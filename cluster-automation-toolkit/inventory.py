#!/usr/bin/env python3
import json, argparse
INV = {
  "all":{"children":["cluster","ungrouped"]},
  "cluster":{"hosts":["phx-ai20","dell-ai01","hpe-ai02"]},
  "_meta":{"hostvars":{
     "phx-ai20":{"ansible_host":"10.0.10.6"},
     "dell-ai01":{"ansible_host":"10.0.10.11"},
     "hpe-ai02":{"ansible_host":"10.0.10.12"}
  }}
}
def main():
    p=argparse.ArgumentParser();g=p.add_mutually_exclusive_group(required=True)
    g.add_argument('--list',action='store_true');g.add_argument('--host')
    a=p.parse_args()
    print(json.dumps(INV if a.list else {}))
if __name__=="__main__":main()
