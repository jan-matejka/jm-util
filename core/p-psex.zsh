#!/bin/sh

fmt="table {{.ID}} {{.Image}} {{.ImageID}} {{.Command}} {{.CreatedHuman}}"
fmt="${fmt} {{.Status}} {{.Ports}} {{.Names}}"
exec podman ps --format "${fmt}" "$@"
