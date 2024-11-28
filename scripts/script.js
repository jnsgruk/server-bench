import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.1/index.js"
import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js"
import { check } from "k6"
import http from "k6/http"

export const options = {
  // A number specifying the number of VUs to run concurrently.
  vus: 10,
  // A string specifying the total duration of the test run.
  duration: "30s",
}

const host = __ENV.K6_HOST || "http://localhost:8080"
const assets = JSON.parse(open(`./paths.json`))
const redirects = JSON.parse(open(`./redirects.json`))

export default function () {
  const responses = http.batch(
    [...assets, ...redirects].map((p) => ["GET", `${host}/${p}`, null, { redirects: 0 }])
  )

  responses.forEach((r) => {
    check(r, {
      status: (res) => {
        return [200, 301, 308].includes(res.status)
      },
    })
  })
}

export function handleSummary(data) {
  return {
    "summary.json": JSON.stringify(data),
    "summary.html": htmlReport(data),
    "summary.txt": textSummary(data, { enableColors: false, indent: "" }),
    stdout: "\n" + textSummary(data, { enableColors: true, indent: "" }) + "\n\n",
  }
}
