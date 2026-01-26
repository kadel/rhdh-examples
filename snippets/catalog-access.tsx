import {
    Table,
    TableColumn,
    Progress,
    ResponseErrorPanel,
  } from '@backstage/core-components';
  import { useApi } from '@backstage/core-plugin-api';
  import { catalogApiRef } from '@backstage/plugin-catalog-react';
  import { Entity, RELATION_OWNED_BY } from '@backstage/catalog-model';
  import useAsync from 'react-use/lib/useAsync';
  
  type CatalogComponentsTableProps = {
    entities: Entity[];
  };
  
  export const CatalogComponentsTable = ({
    entities,
  }: CatalogComponentsTableProps) => {
    const columns: TableColumn<Entity>[] = [
      {
        title: 'Name',
        field: 'metadata.name',
        highlight: true,
      },
      {
        title: 'Description',
        field: 'metadata.description',
        render: (entity: Entity) =>
          entity.metadata.description || <em>No description</em>,
      },
      {
        title: 'Type',
        field: 'spec.type',
        render: (entity: Entity) => (entity.spec?.type as string) || '-',
      },
      {
        title: 'Lifecycle',
        field: 'spec.lifecycle',
        render: (entity: Entity) => (entity.spec?.lifecycle as string) || '-',
      },
      {
        title: 'Owner',
        render: (entity: Entity) => {
          const ownerRelation = entity.relations?.find(
            r => r.type === RELATION_OWNED_BY,
          );
          return ownerRelation?.targetRef || '-';
        },
      },
    ];
  
    return (
      <Table
        title="Software Catalog Components"
        options={{ search: true, paging: true, pageSize: 10 }}
        columns={columns}
        data={entities}
      />
    );
  };
  
  export const ExampleFetchComponent = () => {
    const catalogApi = useApi(catalogApiRef);
  
    const { value, loading, error } = useAsync(async (): Promise<Entity[]> => {
      const response = await catalogApi.getEntities({
        filter: { kind: 'Component' },
      });
      return response.items;
    }, [catalogApi]);
  
    if (loading) {
      return <Progress />;
    } else if (error) {
      return <ResponseErrorPanel error={error} />;
    }
  
    return <CatalogComponentsTable entities={value || []} />;
  };
  