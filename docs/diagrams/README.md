# Diagrams

Mermaid source files for the project's diagrams. GitHub renders Mermaid
automatically inside `.md` files (see the embeds in `docs/architecture.md`,
`docs/ERD.md`, `docs/HLD.md`, and `docs/LLD.md`) — these `.mmd` files are
the raw, reusable source, handy for editing or rendering elsewhere (e.g.
pasting into [mermaid.live](https://mermaid.live) or exporting to PNG/SVG
for Power BI / slide decks).

| File | Shows | Embedded in |
|---|---|---|
| [`architecture.mmd`](architecture.mmd) | End-to-end data flow: sources → Bronze → Silver → Gold → API/BI | [`docs/architecture.md`](../architecture.md) |
| [`erd.mmd`](erd.mmd) | Entity-relationship diagram for the raw (Bronze) tables | [`docs/ERD.md`](../ERD.md) |
| [`dbt_lineage.mmd`](dbt_lineage.mmd) | dbt model lineage: raw sources → staging → marts | [`docs/LLD.md`](../LLD.md) |
| [`pipeline_dag.mmd`](pipeline_dag.mmd) | Airflow DAG task order | [`docs/HLD.md`](../HLD.md) |

## Regenerating an image

```bash
npm install -g @mermaid-js/mermaid-cli
mmdc -i docs/diagrams/architecture.mmd -o docs/diagrams/architecture.png
```
