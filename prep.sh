#!/bin/sh

echo "Preapring for build..."
cp -r ./misc ./pre-install.sh ./post-install.sh ./releng/airootfs/root/
chmod +x ./releng/airootfs/root/pre-install.sh
chmod +x ./releng/airootfs/root/pre-install.sh
