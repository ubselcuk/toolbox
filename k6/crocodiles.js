// docker run --rm -i --platform linux/amd64 -v $(pwd):/scripts grafana/k6 run /scripts/test.js

import http from 'k6/http';
import { sleep } from 'k6';

export let options = {
  vus: 10, // number of virtual users
  duration: '30s', // duration of the test
};
const URL = 'https://test-api.k6.io/public/crocodiles/1/';

export default function () {
  let res = http.get(URL);
  sleep(1);
}