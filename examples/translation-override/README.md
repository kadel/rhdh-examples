# Translation Override Example

This example demonstrates how to customize UI labels and text in Red Hat Developer Hub (RHDH) using the i18n translation override feature. This allows you to rename filter labels, buttons, and other UI elements without modifying the source code.

## What's Included

- **Custom Translation File**: JSON file with translation overrides for catalog picker labels
- **ConfigMap Mount**: Mounts the translation file into the RHDH container
- **i18n Configuration**: Configures RHDH to load the custom translations

## How It Works

RHDH supports i18n (internationalization) with the ability to override default translations. By providing a JSON file with custom translations and mounting it into the container, you can customize any translatable text in the UI.

### Translation File Format

The translation file uses a nested structure: `plugin-id` -> `locale` -> `translation-key`:

```json
{
  "catalog-react": {
    "en": {
        "entityKindPicker.title": "MyKind",
        "entityTypePicker.title": "MyType",
        "entityOwnerPicker.title": "MyOwner",
        "entityLifecyclePicker.title": "MyLifecycle",
        "fields.entityTagsPicker.title": "MyTags",
        "entityNamespacePicker.title": "MyNamespace"
    }
  }
}
```

In this example, the catalog filter labels are renamed:
- "Kind" becomes "MyKind"
- "Type" becomes "MyType"
- "Owner" becomes "MyOwner"
- etc.

### App Configuration

The `app-config.yaml` configures RHDH to load the translation overrides:

```yaml
i18n:
  locales:
    - en
  overrides: 
    - /opt/app-root/src/translations/allTranslations.json
```

The `i18n.overrides` array points to the mounted translation file location inside the container.

## Configuration Details

### ConfigMap for Translations

The translation file is packaged as a ConfigMap:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

configMapGenerator:
  - name: all-translations
    files:
      - allTranslations.json
    options:
      disableNameSuffixHash: true
```

### Helm Configuration

For Helm deployments, the ConfigMap is mounted as an extra volume:

```yaml
upstream:
  backstage:
      extraVolumeMounts:
        # we need to copy whole extraVolumeMounts directory form original values.yaml beucase there is no way to 
        # easily extend arrays in helm
        - mountPath: /opt/app-root/src/dynamic-plugins-root
          name: dynamic-plugins-root
        - name: temp
          mountPath: /tmp
        #  this is what is specific to this example
        - mountPath: /opt/app-root/src/translations/
          name: all-translations
      
      extraVolumes:
        # we need to copy whole extraVolumes directory form original values.yaml beucase there is no way to 
        # easily extend arrays in helm
        - ephemeral:
            volumeClaimTemplate:
              spec:
                accessModes:
                  - ReadWriteOnce
                resources:
                  requests:
                    storage: 1Gi
          name: dynamic-plugins-root
        - configMap:
            defaultMode: 420
            name: dynamic-plugins
            optional: true
          name: dynamic-plugins
        - name: dynamic-plugins-npmrc
          secret:
            defaultMode: 420
            optional: true
            secretName: '{{ printf "%s-dynamic-plugins-npmrc" .Release.Name }}'
        - name: dynamic-plugins-registry-auth
          secret:
            defaultMode: 416
            optional: true
            secretName: '{{ printf "%s-dynamic-plugins-registry-auth" .Release.Name }}'
        - name: npmcacache
          emptyDir: {}
        - name: temp
          emptyDir: {}
        #  this is what is specific to this example
        - name: all-translations
          configMap:
            name: all-translations
```

### Operator Configuration

For Operator deployments, the ConfigMap is mounted via `extraFiles`:

```yaml
apiVersion: rhdh.redhat.com/v1alpha3
kind: Backstage
metadata:
  name: my-rhdh
spec:
  application:
    extraFiles:
      configMaps:
        - name: all-translations
          mountPath: /opt/app-root/src/translations
```

## Finding Translation Keys

To find available translation keys for a plugin:

1. Check the plugin's source code for `useTranslationRef` usage
2. Look for `*Translation.ts` files in the plugin package
3. Common plugins with translations:
   - `catalog-react`: Catalog UI components
   - `scaffolder`: Software Templates UI
   - `techdocs`: TechDocs UI

## Installation

Choose either Helm or Operator-based deployment:

### Using Helm

```bash
cd helm
./install.sh
```

### Using the RHDH Operator

```bash
cd operator
./install.sh
```

## Uninstallation

### Using Helm

```bash
cd helm
./uninstall.sh
```

### Using the RHDH Operator

```bash
cd operator
./uninstall.sh
```

## References

- [RHDH Localization Documentation](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.8/html/customizing_red_hat_developer_hub/assembly-localization-in-rhdh_assembly-localization-in-rhdh#prov-overriding-translations_assembly-localization-in-rhdh)
- [RHDH Documentation](https://docs.redhat.com/en/documentation/red_hat_developer_hub)
- [Backstage i18n Documentation](https://backstage.io/docs/plugins/internationalization)
