#!/usr/bin/env python3

import tempfile
import urllib3
import yaml

url = "https://raw.githubusercontent.com/kubernetes/website/main/data/releases/schedule.yaml"

http = urllib3.PoolManager()
r = http.request('GET', url, preload_content=False)
data = r.data
r.release_conn()

parsed_data = yaml.safe_load(data)


for elem in parsed_data.get('schedules', []):
    print(elem.get('next').get('release'))
