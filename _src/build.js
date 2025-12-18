#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const YAML = require('yaml');

// Paths
const ROOT_DIR = path.resolve(__dirname, '..');
const SRC_DIR = __dirname;
const BASE_DIR = path.join(SRC_DIR, '_base');
const EXAMPLES_SRC_DIR = path.join(SRC_DIR, '_examples');
const OUTPUT_DIR = path.join(ROOT_DIR, 'examples');

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Deep merge two objects. Arrays from overlay replace base arrays.
 * @param {object} base - Base object
 * @param {object} overlay - Overlay object (takes precedence)
 * @returns {object} Merged object
 */
function deepMerge(base, overlay) {
  if (overlay === undefined) return base;
  if (base === undefined) return overlay;

  // If either is not an object, overlay wins
  if (typeof base !== 'object' || base === null ||
      typeof overlay !== 'object' || overlay === null) {
    return overlay;
  }

  // If overlay is an array, it replaces base
  if (Array.isArray(overlay)) {
    return overlay;
  }

  // If base is an array but overlay is object, overlay wins
  if (Array.isArray(base)) {
    return overlay;
  }

  // Both are objects, merge recursively
  const result = { ...base };
  for (const key of Object.keys(overlay)) {
    result[key] = deepMerge(base[key], overlay[key]);
  }
  return result;
}

/**
 * Deep merge YAML documents, preserving comments from both.
 * Overlay comments take precedence when there's a conflict.
 * @param {YAML.Document} baseDoc - Base YAML document
 * @param {YAML.Document} overlayDoc - Overlay YAML document
 * @returns {YAML.Document} Merged document
 */
function mergeYamlDocuments(baseDoc, overlayDoc) {
  if (!overlayDoc || !overlayDoc.contents) return baseDoc;
  if (!baseDoc || !baseDoc.contents) return overlayDoc;

  const result = baseDoc.clone();
  mergeNodes(result.contents, overlayDoc.contents);
  return result;
}

/**
 * Recursively merge YAML nodes, preserving comments
 * @param {YAML.Node} baseNode - Base node (mutated)
 * @param {YAML.Node} overlayNode - Overlay node
 */
function mergeNodes(baseNode, overlayNode) {
  if (!overlayNode) return;

  // If overlay is not a map, or base is not a map, replace
  if (!YAML.isMap(baseNode) || !YAML.isMap(overlayNode)) {
    return;
  }

  // Merge map items
  for (const overlayItem of overlayNode.items) {
    const key = overlayItem.key.value !== undefined ? overlayItem.key.value : overlayItem.key;
    const baseItem = baseNode.items.find(item => {
      const baseKey = item.key.value !== undefined ? item.key.value : item.key;
      return baseKey === key;
    });

    if (baseItem) {
      // Key exists in base
      if (YAML.isMap(baseItem.value) && YAML.isMap(overlayItem.value)) {
        // Both are maps, merge recursively
        mergeNodes(baseItem.value, overlayItem.value);
        // Preserve overlay's comment if it has one
        if (overlayItem.key.commentBefore) {
          baseItem.key.commentBefore = overlayItem.key.commentBefore;
        }
        if (overlayItem.value.commentBefore) {
          baseItem.value.commentBefore = overlayItem.value.commentBefore;
        }
      } else {
        // Replace value (including arrays), preserve overlay's comments
        baseItem.value = overlayItem.value.clone ? overlayItem.value.clone() : overlayItem.value;
        if (overlayItem.key.commentBefore) {
          baseItem.key.commentBefore = overlayItem.key.commentBefore;
        }
      }
    } else {
      // Key doesn't exist in base, add it with comments
      baseNode.items.push(overlayItem.clone ? overlayItem.clone() : overlayItem);
    }
  }
}

/**
 * Parse an .env file into a key-value object
 * @param {string} content - Content of the .env file
 * @returns {object} Key-value pairs
 */
function parseEnvFile(content) {
  const result = {};
  const lines = content.split('\n');

  for (const line of lines) {
    const trimmed = line.trim();
    // Skip empty lines and comments
    if (!trimmed || trimmed.startsWith('#')) continue;

    const eqIndex = trimmed.indexOf('=');
    if (eqIndex > 0) {
      const key = trimmed.substring(0, eqIndex);
      const value = trimmed.substring(eqIndex + 1);
      result[key] = value;
    }
  }

  return result;
}

/**
 * Convert env object back to .env file content
 * @param {object} envObj - Key-value pairs
 * @returns {string} .env file content
 */
function envToString(envObj) {
  return Object.entries(envObj)
    .map(([key, value]) => `${key}=${value}`)
    .join('\n');
}

/**
 * Merge two .env files (overlay values override base)
 * @param {string} baseContent - Base .env content
 * @param {string} overlayContent - Overlay .env content
 * @returns {string} Merged .env content
 */
function mergeEnvFiles(baseContent, overlayContent) {
  const base = parseEnvFile(baseContent || '');
  const overlay = parseEnvFile(overlayContent || '');
  const merged = { ...base, ...overlay };
  return envToString(merged);
}

/**
 * Read file if it exists, otherwise return undefined
 * @param {string} filePath - Path to file
 * @returns {string|undefined} File content or undefined
 */
function readFileIfExists(filePath) {
  try {
    return fs.readFileSync(filePath, 'utf8');
  } catch (e) {
    if (e.code === 'ENOENT') return undefined;
    throw e;
  }
}

/**
 * Read and parse YAML file as Document if it exists (preserves comments)
 * @param {string} filePath - Path to YAML file
 * @returns {YAML.Document|undefined} Parsed YAML Document or undefined
 */
function readYamlDocIfExists(filePath) {
  const content = readFileIfExists(filePath);
  if (content === undefined) return undefined;
  return YAML.parseDocument(content);
}

/**
 * Read and parse YAML file if it exists
 * @param {string} filePath - Path to YAML file
 * @returns {object|undefined} Parsed YAML or undefined
 */
function readYamlIfExists(filePath) {
  const content = readFileIfExists(filePath);
  if (content === undefined) return undefined;
  return YAML.parse(content);
}

/**
 * Ensure directory exists, create if not
 * @param {string} dirPath - Directory path
 */
function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

/**
 * Write content to file, creating directories as needed
 * @param {string} filePath - Path to file
 * @param {string} content - Content to write
 */
function writeFile(filePath, content) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, content);
}

/**
 * Copy a directory recursively
 * @param {string} src - Source directory
 * @param {string} dest - Destination directory
 */
function copyDir(src, dest) {
  ensureDir(dest);
  const entries = fs.readdirSync(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

/**
 * Check if a path exists and is a directory
 * @param {string} dirPath - Path to check
 * @returns {boolean}
 */
function isDirectory(dirPath) {
  try {
    return fs.statSync(dirPath).isDirectory();
  } catch {
    return false;
  }
}

// ============================================================================
// Kustomize Functions
// ============================================================================

/**
 * Run kubectl kustomize on a directory
 * @param {string} directory - Directory containing kustomization.yaml
 * @returns {string} Generated YAML output (multi-document)
 */
function runKustomize(directory) {
  try {
    const output = execSync(`kubectl kustomize ${directory}`, {
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    });
    return output;
  } catch (e) {
    throw new Error(`Kustomize failed: ${e.stderr || e.message}`);
  }
}

/**
 * Merge base kustomization.yaml with example-specific kustomization.yaml
 * Arrays (like configMapGenerator, secretGenerator) are concatenated.
 * @param {object} base - Base kustomization object
 * @param {object} overlay - Example-specific kustomization object
 * @returns {object} Merged kustomization object
 */
function mergeKustomizations(base, overlay) {
  if (!overlay) return base;
  if (!base) return overlay;

  const result = { ...base };

  // Arrays that should be concatenated rather than replaced
  const arrayKeys = ['resources', 'configMapGenerator', 'secretGenerator', 'patchesStrategicMerge', 'patchesJson6902'];

  for (const key of Object.keys(overlay)) {
    if (arrayKeys.includes(key) && Array.isArray(base[key]) && Array.isArray(overlay[key])) {
      // Concatenate arrays
      result[key] = [...base[key], ...overlay[key]];
    } else if (typeof overlay[key] === 'object' && !Array.isArray(overlay[key]) &&
               typeof base[key] === 'object' && !Array.isArray(base[key])) {
      // Deep merge objects
      result[key] = { ...base[key], ...overlay[key] };
    } else {
      // Replace value
      result[key] = overlay[key];
    }
  }

  return result;
}

/**
 * Split multi-document YAML output into individual resource files
 * @param {string} yamlContent - Multi-document YAML string
 * @param {string} outputDir - Directory to write files to
 */
function splitKustomizeOutput(yamlContent, outputDir) {
  // Parse all documents
  const documents = YAML.parseAllDocuments(yamlContent);

  for (const doc of documents) {
    if (!doc.contents) continue;

    const resource = doc.toJSON();
    if (!resource || !resource.kind || !resource.metadata?.name) continue;

    // Generate filename using <kind>-<name>.yaml pattern
    const kind = resource.kind.toLowerCase();
    const name = resource.metadata.name;
    const filename = `${kind}-${name}.yaml`;

    const filePath = path.join(outputDir, filename);
    writeFile(filePath, YAML.stringify(resource, { lineWidth: 0 }));
  }
}

// ============================================================================
// Template Processing
// ============================================================================

/**
 * Process README template, replacing {{include:path}} with file contents
 * @param {string} templateContent - Template content
 * @param {string} sourceDir - Source directory for resolving relative paths
 * @returns {string} Processed content
 */
function processTemplate(templateContent, sourceDir) {
  const includeRegex = /\{\{include:([^}]+)\}\}/g;

  return templateContent.replace(includeRegex, (match, relativePath) => {
    const filePath = path.join(sourceDir, relativePath.trim());
    try {
      return fs.readFileSync(filePath, 'utf8').trim();
    } catch (e) {
      console.warn(`  Warning: Could not include file ${relativePath}: ${e.message}`);
      return `<!-- File not found: ${relativePath} -->`;
    }
  });
}

// ============================================================================
// Example Builder
// ============================================================================

/**
 * Build a single example
 * @param {string} exampleName - Name of the example
 * @param {string} exampleSrcDir - Path to example source directory
 */
function buildExample(exampleName, exampleSrcDir) {
  const exampleOutputDir = path.join(OUTPUT_DIR, exampleName);

  // -------------------------------------------------------------------------
  // 1. Merge configs (with comment preservation)
  // -------------------------------------------------------------------------

  // App config - merge with comment preservation
  const baseAppConfigDoc = readYamlDocIfExists(path.join(BASE_DIR, 'config', 'app-config.yaml'));
  const exampleAppConfigDoc = readYamlDocIfExists(path.join(exampleSrcDir, 'config', 'app-config.yaml'));

  let mergedAppConfigDoc;
  if (baseAppConfigDoc && exampleAppConfigDoc) {
    mergedAppConfigDoc = mergeYamlDocuments(baseAppConfigDoc, exampleAppConfigDoc);
  } else {
    mergedAppConfigDoc = exampleAppConfigDoc || baseAppConfigDoc || new YAML.Document({});
  }
  const mergedAppConfigYaml = mergedAppConfigDoc.toString();

  // Dynamic plugins (no example override expected, just use base)
  const dynamicPluginsContent = readFileIfExists(path.join(BASE_DIR, 'config', 'dynamic-plugins.yaml')) || '';
  const dynamicPlugins = YAML.parse(dynamicPluginsContent) || {};

  // Secrets env
  const baseSecretsEnv = readFileIfExists(path.join(BASE_DIR, 'config', 'secrets.env')) || '';
  const exampleSecretsEnv = readFileIfExists(path.join(exampleSrcDir, 'config', 'secrets.env')) || '';
  const mergedSecretsEnv = mergeEnvFiles(baseSecretsEnv, exampleSecretsEnv);

  // -------------------------------------------------------------------------
  // 2. Write merged configs to output/config/
  // -------------------------------------------------------------------------

  const configOutputDir = path.join(exampleOutputDir, 'config');
  writeFile(path.join(configOutputDir, 'app-config.yaml'), mergedAppConfigYaml);
  writeFile(path.join(configOutputDir, 'dynamic-plugins.yaml'), dynamicPluginsContent);
  writeFile(path.join(configOutputDir, 'secrets.env'), mergedSecretsEnv);

  // Merge base kustomization.yaml with example-specific kustomization.yaml
  const baseKustomization = readYamlIfExists(path.join(BASE_DIR, 'config', 'kustomization.yaml'));
  const exampleKustomization = readYamlIfExists(path.join(exampleSrcDir, 'config', 'kustomization.yaml'));
  const mergedKustomization = mergeKustomizations(baseKustomization, exampleKustomization);
  writeFile(path.join(configOutputDir, 'kustomization.yaml'), YAML.stringify(mergedKustomization, { lineWidth: 0 }));

  // Copy any additional files referenced by example kustomization (e.g., certificate bundles)
  const exampleConfigDir = path.join(exampleSrcDir, 'config');
  if (isDirectory(exampleConfigDir)) {
    const configFiles = fs.readdirSync(exampleConfigDir);
    for (const file of configFiles) {
      // Skip files we've already handled
      if (['app-config.yaml', 'secrets.env', 'kustomization.yaml'].includes(file)) continue;
      const srcFile = path.join(exampleConfigDir, file);
      const destFile = path.join(configOutputDir, file);
      // Only copy files, not directories
      if (fs.statSync(srcFile).isFile()) {
        fs.copyFileSync(srcFile, destFile);
      }
    }
  }

  // Run kustomize to generate K8s resources
  const kustomizeOutput = runKustomize(configOutputDir);

  // Remove kustomization.yaml from output (it was only needed to run kustomize)
  fs.unlinkSync(path.join(configOutputDir, 'kustomization.yaml'));

  // -------------------------------------------------------------------------
  // 3. Generate Helm output
  // -------------------------------------------------------------------------

  const helmOutputDir = path.join(exampleOutputDir, 'helm');
  const helmConfigsDir = path.join(helmOutputDir, 'resources');

  // Merge Helm values with comment preservation
  const baseHelmValuesDoc = readYamlDocIfExists(path.join(BASE_DIR, 'helm', 'values.yaml.tmpl'));
  const exampleHelmPatchDoc = readYamlDocIfExists(path.join(exampleSrcDir, 'helm', 'patches', 'values.yaml'));

  let mergedHelmValuesDoc;
  if (baseHelmValuesDoc && exampleHelmPatchDoc) {
    mergedHelmValuesDoc = mergeYamlDocuments(baseHelmValuesDoc, exampleHelmPatchDoc);
  } else {
    mergedHelmValuesDoc = exampleHelmPatchDoc || baseHelmValuesDoc || new YAML.Document({});
  }

  // Embed dynamic plugins under global.dynamic using Document API to preserve comments
  const dynamicPluginsDoc = YAML.parseDocument(dynamicPluginsContent);
  if (dynamicPluginsDoc.contents && mergedHelmValuesDoc.contents) {
    // Find or create global.dynamic in the merged doc
    let globalNode = mergedHelmValuesDoc.contents.items?.find(item => {
      const key = item.key.value !== undefined ? item.key.value : item.key;
      return key === 'global';
    });

    if (globalNode && YAML.isMap(globalNode.value)) {
      // Find dynamic key and replace its value
      let dynamicNode = globalNode.value.items?.find(item => {
        const key = item.key.value !== undefined ? item.key.value : item.key;
        return key === 'dynamic';
      });
      if (dynamicNode) {
        dynamicNode.value = dynamicPluginsDoc.contents;
      }
    }
  }

  // Embed app-config under upstream.backstage.appConfig
  if (mergedHelmValuesDoc.contents) {
    let upstreamNode = mergedHelmValuesDoc.contents.items?.find(item => {
      const key = item.key.value !== undefined ? item.key.value : item.key;
      return key === 'upstream';
    });

    if (upstreamNode && YAML.isMap(upstreamNode.value)) {
      let backstageNode = upstreamNode.value.items?.find(item => {
        const key = item.key.value !== undefined ? item.key.value : item.key;
        return key === 'backstage';
      });

      if (backstageNode && YAML.isMap(backstageNode.value)) {
        let appConfigNode = backstageNode.value.items?.find(item => {
          const key = item.key.value !== undefined ? item.key.value : item.key;
          return key === 'appConfig';
        });

        if (appConfigNode) {
          appConfigNode.value = mergedAppConfigDoc.contents;
        }
      }
    }
  }

  writeFile(path.join(helmOutputDir, 'values.yaml'), mergedHelmValuesDoc.toString());

  // Generate K8s resources for Helm using kustomize output
  splitKustomizeOutput(kustomizeOutput, helmConfigsDir);

  // Copy scripts from _base
  fs.copyFileSync(path.join(BASE_DIR, 'helm', 'install.sh'), path.join(helmOutputDir, 'install.sh'));
  fs.copyFileSync(path.join(BASE_DIR, 'helm', 'uninstall.sh'), path.join(helmOutputDir, 'uninstall.sh'));

  // -------------------------------------------------------------------------
  // 4. Generate Operator output
  // -------------------------------------------------------------------------

  const operatorOutputDir = path.join(exampleOutputDir, 'operator');
  const operatorConfigsDir = path.join(operatorOutputDir, 'resources');

  // Merge RHDH CR with comment preservation
  const baseRhdhCrDoc = readYamlDocIfExists(path.join(BASE_DIR, 'operator', 'rhdh.yaml'));
  const exampleRhdhPatchDoc = readYamlDocIfExists(path.join(exampleSrcDir, 'operator', 'patches', 'rhdh.yaml'));

  let mergedRhdhCrDoc;
  if (baseRhdhCrDoc && exampleRhdhPatchDoc) {
    mergedRhdhCrDoc = mergeYamlDocuments(baseRhdhCrDoc, exampleRhdhPatchDoc);
  } else {
    mergedRhdhCrDoc = exampleRhdhPatchDoc || baseRhdhCrDoc || new YAML.Document({});
  }

  writeFile(path.join(operatorOutputDir, 'rhdh.yaml'), mergedRhdhCrDoc.toString());

  // Generate K8s resources for Operator using kustomize output
  splitKustomizeOutput(kustomizeOutput, operatorConfigsDir);

  // Copy scripts from _base
  fs.copyFileSync(path.join(BASE_DIR, 'operator', 'install.sh'), path.join(operatorOutputDir, 'install.sh'));
  fs.copyFileSync(path.join(BASE_DIR, 'operator', 'uninstall.sh'), path.join(operatorOutputDir, 'uninstall.sh'));

  // -------------------------------------------------------------------------
  // 5. Copy extra-services YAML files to resources directories
  // -------------------------------------------------------------------------

  const extraServicesDir = path.join(exampleSrcDir, 'extra-services');
  if (isDirectory(extraServicesDir)) {
    const extraFiles = fs.readdirSync(extraServicesDir);
    for (const file of extraFiles) {
      if (file.endsWith('.yaml') || file.endsWith('.yml')) {
        const srcFile = path.join(extraServicesDir, file);
        fs.copyFileSync(srcFile, path.join(helmConfigsDir, file));
        fs.copyFileSync(srcFile, path.join(operatorConfigsDir, file));
      }
    }
  }

  // -------------------------------------------------------------------------
  // 6. Copy terraform directory if it exists
  // -------------------------------------------------------------------------

  const terraformDir = path.join(exampleSrcDir, 'terraform');
  if (isDirectory(terraformDir)) {
    copyDir(terraformDir, path.join(exampleOutputDir, 'terraform'));
  }

  // -------------------------------------------------------------------------
  // 7. Process README template
  // -------------------------------------------------------------------------

  const readmeTemplate = readFileIfExists(path.join(exampleSrcDir, 'README.md.tmpl'));
  if (readmeTemplate) {
    const processedReadme = processTemplate(readmeTemplate, exampleSrcDir);
    writeFile(path.join(exampleOutputDir, 'README.md'), processedReadme);
  }

  return true;
}

// ============================================================================
// Main Build Function
// ============================================================================

function build() {
  console.log('Building RHDH examples...\n');

  // Clean output directory
  if (fs.existsSync(OUTPUT_DIR)) {
    fs.rmSync(OUTPUT_DIR, { recursive: true });
  }

  // Validate base directory exists
  if (!isDirectory(BASE_DIR)) {
    console.error(`Error: Base directory not found: ${BASE_DIR}`);
    process.exit(1);
  }

  // Discover examples
  if (!isDirectory(EXAMPLES_SRC_DIR)) {
    console.error(`Error: Examples source directory not found: ${EXAMPLES_SRC_DIR}`);
    process.exit(1);
  }

  const examples = fs.readdirSync(EXAMPLES_SRC_DIR, { withFileTypes: true })
    .filter(entry => entry.isDirectory())
    .map(entry => entry.name);

  if (examples.length === 0) {
    console.log('No examples found to build.');
    return;
  }

  // Build each example
  const results = [];
  for (const exampleName of examples) {
    try {
      const exampleSrcDir = path.join(EXAMPLES_SRC_DIR, exampleName);
      buildExample(exampleName, exampleSrcDir);
      results.push({ name: exampleName, success: true });
      console.log(`  ✓ ${exampleName} (helm + operator)`);
    } catch (e) {
      results.push({ name: exampleName, success: false, error: e.message });
      console.error(`  ✗ ${exampleName}: ${e.message}`);
    }
  }

  // Summary
  const successCount = results.filter(r => r.success).length;
  console.log(`\nBuilt ${successCount}/${examples.length} examples to examples/`);

  if (successCount < examples.length) {
    process.exit(1);
  }
}

// Run build
build();
