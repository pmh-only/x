import { MWAAClient, InvokeRestApiCommand } from '@aws-sdk/client-mwaa'

export const handler = async (event) => {
  const client = new MWAAClient({})

  const cmd = new InvokeRestApiCommand({
    Name: 'project-airflow',
    Path: `/api/v1/dags/my_dag/dagRuns`,
    Method: 'POST',
    QueryStringParameters: {},
    Body: new TextEncoder().encode(JSON.stringify({
      logical_date: new Date().toISOString(),
      conf: {
        bucket: event.detail.bucket.name,
        key: decodeURIComponent(event.detail.object.key.replace(/\+/g, '%20'))
      }
    }))
  })

  await client.send(cmd)
}
