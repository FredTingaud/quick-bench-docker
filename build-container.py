#!/usr/bin/env python3

import json
import argparse
from functools import reduce
import subprocess
import os

def pretty(s):
   print("")
   print(f"\033[91m***> {s}\033[0m")

def concat(x, key, val):
   x.extend(["--build-arg", f"{key}={val}"])
   return x

def pushTarget(target):
   pretty(f"Pushing {target} to Docker Hub")
   subprocess.run(["docker", "push", f"fredtingaud/quick-bench:{target}"])

def testTarget(target):
   pretty(f"Testing {target}")
   env = os.environ.copy()
   env["QB_VERSION"] = target
   res = subprocess.run(["npm", "run", "system-test"], cwd="../quick-bench-back-end", env=env)
   return res.returncode

def treatTarget(target, force):
   params = data[target]
   dockerfile = params.pop("docker")
   command = ["docker", "build", "-t", f"fredtingaud/quick-bench:{target}", "-f", f"{dockerfile}"]
   command.extend(["--no-cache"] if force else [])
   command.extend(reduce(lambda x, key: concat(x, key, params[key]), params, []) if params else [])
   command.append(".")
   pretty(f"Building Docker Container for {target}")
   res = subprocess.run(command)
   if res.returncode != 0:
      return res.returncode
   else:
      return testTarget(target)

def main():
   parser = argparse.ArgumentParser()

   parser.add_argument("-f", "--force", help="build without cache", action="store_true")
   parser.add_argument("-s", "--skip", nargs="*", default=[], help="build all containers except the passed ones")
   parser.add_argument("-p", "--push", help="push the result to docker-hub", action="store_true")

   targetGroups = parser.add_mutually_exclusive_group(required=True)
   targetGroups.add_argument("target", help="a given container to build", nargs='*', default=[])
   targetGroups.add_argument("-a", "--all", help="build all the containers", action="store_true")
   targetGroups.add_argument("--clang", help="build all clang containers", action="store_true")
   targetGroups.add_argument("--gcc", help="build all gcc containers", action="store_true")

   args = parser.parse_args()

   if args.target:
      targets = args.target
   elif args.all:
      targets = data.keys()
   elif args.clang:
      targets = filter(lambda k: k.startswith("clang"), data.keys())
   elif args.gcc:
      targets = filter(lambda k: k.startswith("gcc"), data.keys())

   filtered = set(targets).difference(set(args.skip))
   for target in filtered:
      retcode = treatTarget(target, args.force)
      if retcode == 0:
         pretty(f"Container successfully built for {target}")
         if args.push:
            pushTarget(target)
      else:
         pretty(f"Container couldn't be built for {target} - retcode={retcode}")

with open('containers.json') as f:
  data = json.load(f)

if __name__ == "__main__":
   main()
