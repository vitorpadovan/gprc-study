import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '10s', target: 20 },
		{ duration: '20s', target: 8500 },
		{ duration: '10s', target: 1500 },
		{ duration: '10s', target: 25000 },
		{ duration: '30s', target: 15500 },
		{ duration: '30s', target: 300 },
        { duration: '1m30s', target: 1500 },
        { duration: '20s', target: 0 },
    ],
};

export default function () {
	const body = {
		Usuario: __VU,
		Iteracao: __ITER
	}
	const payload = JSON.stringify(body)
	const headers = { 'Content-Type': 'application/json' };
    const res = http.post('http://localhost:8080/Order', payload,{headers} );
    check(res, { 'status was 200': (r) => r.status == 200 });
    sleep(1);
}