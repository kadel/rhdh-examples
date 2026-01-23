# Getting Started with RHDH Dynamic Plugin Development

This guide outlines the process of creating, developing, and packaging a dynamic plugin for Red Hat Developer Hub (RHDH).

## Learning Objectives

By the end of this guide, you will be able to:

- Set up a Backstage development environment with the correct version for your target RHDH instance
- Create a new frontend plugin using the Backstage CLI
- Build common plugin components including pages and entity cards
- Configure the local development harness with RHDH theming
- Export and package a plugin for dynamic loading using the RHDH CLI
- Configure plugin wiring for routes, menu items, and mount points

## Prerequisites

Before starting, ensure the following are available:

- Node.js 22+ and Yarn
- Container runtime (podman or docker)
- Access to a container registry (e.g., `quay.io`) for publishing
- `@red-hat-developer-hub/cli` (will be used via npx)
- [RHDH Local](https://github.com/redhat-developer/rhdh-local/) instance (for local testing)

## Workflow Overview

1. **Determine RHDH Version** - Identify target RHDH version for compatibility
2. **Create Backstage Application** - Scaffold Backstage app with matching version
3. **Create Frontend Plugin** - Generate new frontend plugin using Backstage CLI
4. **Implement Plugin Components** - Build React components and exports
5. **Test Plugin Locally** - Verify functionality in the development harness
6. **Export as Dynamic Plugin** - Build and export using RHDH CLI
7. **Package as OCI Image** - Create container image for deployment
8. **Configure Plugin Wiring** - Define routes, mount points, and menu items

## Step 1: Determine RHDH Version

Check the target RHDH version and find the compatible Backstage version. This ensures your plugin uses dependencies compatible with the RHDH instance it will run on.

| RHDH Version      | Backstage Version | create-app Version |
| ----------------- | ----------------- | ------------------ |
| 1.9 / pre-release | 1.45.3            | 0.7.6              |
| 1.8               | 1.42.5            | 0.7.3              |
| 1.7               | 1.39.1            | 0.6.2              |
| 1.6               | 1.36.1            | 0.5.25             |

## Step 2: Create Backstage Application

To ensure we are using correct versions of all Backstage packages, we will use the `create-app` command to create a new Backstage application.
The only purpose this serves is to ensure you can later create the plugin using the correct version of the Backstage CLI.
In the future, we will have separate tooling that won't require this step.

```bash
# Create a directory for your workspace
mkdir rhdh-plugin-dev
cd rhdh-plugin-dev

# Initialize the Backstage app
# For RHDH 1.8 (adjust version based on the table above)
npx @backstage/create-app@0.7.3 --path .
```

> [!IMPORTANT]
> **Checkpoint:** Your workspace should now contain `packages/app/`, `packages/backend/`, and `plugins/` directories, along with a root `package.json` with Backstage dependencies.

## Step 3: Create Frontend Plugin

Generate a new frontend plugin using the Backstage CLI. Run this command from the root of your workspace:

```bash
yarn new
```

When prompted, select `frontend-plugin` and enter a plugin ID (e.g., `simple-example`).
The plugin will be created at `plugins/simple-example/`.

> [!IMPORTANT]
> **Checkpoint:** The `plugins/simple-example/` directory should exist with `src/`, `dev/`, and `package.json` files.

### Add RHDH Theme to Plugin Development Harness

By default, the plugin's development harness (`yarn start`) uses standard Backstage themes. To preview your plugin with RHDH styling, configure the RHDH theme package in the plugin.

```bash
cd plugins/simple-example
yarn add --dev @red-hat-developer-hub/backstage-plugin-theme
```

Update `dev/index.tsx` to use RHDH themes:

```tsx
// dev/index.tsx

// Import the RHDH themes from the plugin
import { getAllThemes } from '@red-hat-developer-hub/backstage-plugin-theme';
// ...
// ...
createDevApp()
  // ...
  // ...
  // Add RHDH themes to the development harness
  .addThemes(getAllThemes())
  .render();
```

> [!NOTE]
> This configuration is only for the local development harness (`dev/index.tsx`). When deployed to RHDH, the application shell provides theming automatically.

Now you can start the development server and see your plugin in the browser.

```bash
cd plugins/simple-example
yarn start
```

> [!IMPORTANT]
> **Checkpoint:** The development server should start and open a browser at `http://localhost:3000`. You should see the plugin page with RHDH theming applied.

## Step 4: Implement Plugin Components

### Page Component

By default, the frontend plugin already has a sample page component defined in `src/components/ExampleComponent/`. This page is automatically registered in `src/plugin.ts` as `SimpleExamplePage`.

### Entity Card Component

One of the common extensions is to create a new entity card component.

Create a new component in `src/components/ExampleCard/`:

```tsx
// src/components/ExampleCard/ExampleCard.tsx
import React from 'react';
import { InfoCard } from '@backstage/core-components';
import { useEntity } from '@backstage/plugin-catalog-react';

export const ExampleCard = () => {
  const { entity } = useEntity();
  return (
    <InfoCard title="Simple Example Info">
      <p>Entity: {entity.metadata.name}</p>
    </InfoCard>
  );
};
```

```tsx
// src/components/ExampleCard/index.ts
export { ExampleCard } from './ExampleCard';
```

#### Register the new entity card component

In `src/plugin.ts`, add the new component to the plugin.

```tsx
// src/plugin.ts
import { createComponentExtension } from '@backstage/core-plugin-api';
import { simpleExamplePlugin } from './plugin'; // This is where the plugin instance is defined

// ...
// ...
export const ExampleCard = simpleExamplePlugin.provide(
  createComponentExtension({
    name: 'ExampleCard',
    component: {
      lazy: () =>
        import('./components/ExampleCard').then(m => m.ExampleCard),
    },
  }),
);
```


Export all components in `src/index.ts` so they can be loaded dynamically:

```tsx
// src/index.ts
export { simpleExamplePlugin, SimpleExamplePage, ExampleCard } from './plugin';
```

> [!IMPORTANT]
> **Checkpoint:** Your plugin should have the following new files: `src/components/ExampleCard/ExampleCard.tsx` and `src/components/ExampleCard/index.ts`. The `src/plugin.ts` should export `ExampleCard`, and `src/index.ts` should re-export it.

## Step 5: Test Plugin Locally

To see your component card in the development harness, update the `dev/index.tsx` file to include the new component card.

```tsx
// dev/index.tsx
// ...
// ...
import { Entity } from '@backstage/catalog-model';
import { EntityProvider } from '@backstage/plugin-catalog-react';
import { Page, Header, Content } from '@backstage/core-components';
import { Grid } from '@material-ui/core';
import { ExampleCard } from '../src/plugin';


// Mock entity for the component card
const mockEntity: Entity = {
  apiVersion: 'backstage.io/v1alpha1',
  kind: 'Component',
  metadata: {
    name: 'example-service',
    description: 'An example service component for plugin development.',
    annotations: {
      'backstage.io/techdocs-ref': 'dir:.',
    },
  },
  spec: {
    type: 'service',
    lifecycle: 'production',
    owner: 'team-platform',
  },
};

// Create a page with the mock entity and the component card
const entityPage = (
  <EntityProvider entity={mockEntity}>
    <Page themeId="service">
      <Header
        title={mockEntity.metadata.name}
        subtitle={`${mockEntity.kind} · ${mockEntity.spec?.type}`}
      />
      <Content>
        <Grid container spacing={3} alignItems="stretch">
          <Grid item md={6} xs={12}>
            <ExampleCard />
          </Grid>
        </Grid>
      </Content>
    </Page>
  </EntityProvider>
);

createDevApp()
  // ...
  // ...
  .addPage({
    element: entityPage,
    title: 'Entity Page',
    path: '/simple-example/entity',
  })
  // ...
  // ...
  .render();
```


Run the development server:

```bash
yarn start
```

> [!IMPORTANT]
> **Checkpoint:** Navigate to `http://localhost:3000/simple-example/entity` in your browser. You should see the Entity Page with your `ExampleCard` component displaying "Entity: example-service".

## Step 6: Export as Dynamic Plugin

Once your plugin is ready, export it as a dynamic plugin using the RHDH CLI. This command prepares the plugin for dynamic loading by generating the required Scalprum and Webpack federation configurations.

```bash
# Ensure you are in the plugin directory
cd plugins/simple-example

# Export the plugin
npx @red-hat-developer-hub/cli@latest plugin export
```

The output will be generated in the `dist-dynamic/` directory:

- `dist-scalprum/`: Contains the Webpack federated modules.
- `package.json`: A modified version of your `package.json` optimized for dynamic loading.

> [!IMPORTANT]
> **Checkpoint:** The `dist-dynamic/` directory should exist and contain `dist-scalprum/` with JavaScript bundles and a `package.json` file.

## Step 7: Package and Publish

### Package as an OCI Image

To deploy the plugin to an RHDH instance running on Kubernetes or OpenShift, package it as an OCI image and push it to a container registry (e.g., Quay.io).

```bash
# Package the plugin into an OCI image
npx @red-hat-developer-hub/cli@latest plugin package \
  --tag quay.io/<namespace>/simple-example:v0.1.0

# Push the image to your registry
podman push quay.io/<namespace>/simple-example:v0.1.0
```

> [!IMPORTANT]
> **Checkpoint:** Run `podman images | grep simple-example` to verify the image was created. After pushing, verify the image exists in your container registry.

### Test Locally with RHDH Local

If you are using [RHDH Local](https://github.com/redhat-developer/rhdh-local/) for testing, you can copy the `dist-dynamic` directory directly into the `local-plugins` folder.

```bash
# Copy the dynamic distribution to RHDH Local
cp -r dist-dynamic/ <RHDH_LOCAL_PATH>/local-plugins/simple-example
```

> [!IMPORTANT]
> **Checkpoint:** The `local-plugins/simple-example/` directory in your RHDH Local installation should contain the plugin files from `dist-dynamic/`, including the `dist-scalprum/` directory and `package.json`.

## Step 8: Configure Plugin Wiring

Dynamic frontend plugins are registered and configured in the `dynamic-plugins.yaml` file. If you are using RHDH Local for development and testing, use `dynamic-plugins.override.yaml` instead. This configuration determines how the plugin is integrated with the RHDH interface, such as adding routes, sidebar menu items, and mount points.

### Configuration Example

```yaml
plugins:
  # Option 1: Load from an OCI image
  - package: oci://quay.io/<namespace>/simple-example:v0.1.0!backstage-plugin-simple-example
    disabled: false
    pluginConfig:
      dynamicPlugins:
        frontend:
          # The package name must match package.json (usually internal.backstage-plugin-<id>)
          internal.backstage-plugin-simple-example:
            dynamicRoutes:
              - path: /simple-example
                # Must match the export in src/index.ts
                importName: SimpleExamplePage
                menuItem:
                  icon: extension
                  text: Simple Example
            mountPoints:
              - mountPoint: entity.page.overview/cards
                # Must match the export in src/index.ts
                importName: ExampleCard
                config:
                  layout:
                    gridColumnEnd: 'span 4'
                  if:
                    allOf:
                      - isKind: component

  # Option 2: Load from local directory (for local RHDH testing)
  # - package: ./local-plugins/simple-example
  #   disabled: false
  #   pluginConfig: ... (same as above)
```

> [!IMPORTANT]
> **Checkpoint:** After restarting RHDH, you should see "Simple Example" in the sidebar menu. Clicking it should display your plugin page. Navigate to any Component entity page to verify the `ExampleCard` appears in the Overview tab.

### Additional Resources

- [Official RHDH Documentation: Frontend Plugin Wiring](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.8/html/installing_and_viewing_plugins_in_red_hat_developer_hub/assembly-front-end-plugin-wiring.adoc_rhdh-extensions-plugins)
- [RHDH GitHub: Frontend Plugin Wiring Guide](https://github.com/redhat-developer/rhdh/blob/main/docs/dynamic-plugins/frontend-plugin-wiring.md)
