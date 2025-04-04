source $stdenv/setup
PATH=$dpkg/bin:$PATH

dpkg -x $src unpacked

cp -r unpacked/* $out/
rm -rf unpacked

# Patch the ELF files to use the Nix dynamic linker and set the rpath to the embedded lib directory
for bin in $out/cinc-workstation/embedded/bin/*; do
    # If the bin is not a ELF file, skip it
    if ! file $bin | grep -q ELF; then continue; fi
    patchelf --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        --set-rpath "$rpath:$out/cinc-workstation/embedded/lib" \
        $bin
done

# Create a wrapper so we can run the binaries without entering a shell
cat > $out/cinc-workstation/bin/cw-wrapper <<EOF
#!$SHELL
/opt/cinc-workstation/bin/"\$@"
EOF
chmod +x $out/cinc-workstation/bin/cw-wrapper

# Create a VBox network configuration allowing all IP's
mkdir -p $out/etc/vbox
cat > $out/etc/vbox/networks.conf <<EOF
* 0.0.0.0/0
EOF
