import http from 'k6/http';
import { sleep } from 'k6';

export let options = {
  vus: 10,
  duration: '10s',
};

const URL = 'https://example.com/foo/bar';
const PAYLOAD = JSON.stringify({
    foo: 'bar',
    bar: 'foo',
});

const PARAMS = {
    headers: {
        'Content-Type': 'application/json',
        'foo': 'bar',
    },
};

export default function () {
  let res = http.post(URL, PAYLOAD, PARAMS);
  sleep(1);
}