#!/bin/bash
pod lib lint PandaFMDB.podspec  --verbose --allow-warnings
pod package PandaFMDB.podspec --force
