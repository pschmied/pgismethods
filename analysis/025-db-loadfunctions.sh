#!/usr/bin/env bash
DB=pgismethods

cat ./025-sausagebuffer.sql |
    psql $DB

