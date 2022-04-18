#!/bin/bash

helmsman -e kiln.env -f kiln.yaml --show-diff --apply
