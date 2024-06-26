#!/usr/bin/env bash
# Copyright (c) 2016-2020 The Bitcoin_Silver Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

export LC_ALL=C
TOPDIR=${TOPDIR:-$(git rev-parse --show-toplevel)}
BUILDDIR=${BUILDDIR:-$TOPDIR}

BINDIR=${BINDIR:-$BUILDDIR/src}
MANDIR=${MANDIR:-$TOPDIR/doc/man}

BITCOIN_SILVERD=${BITCOIN_SILVERD:-$BINDIR/bitcoin_silverd}
BITCOIN_SILVERCLI=${BITCOIN_SILVERCLI:-$BINDIR/bitcoin_silver-cli}
BITCOIN_SILVERTX=${BITCOIN_SILVERTX:-$BINDIR/bitcoin_silver-tx}
WALLET_TOOL=${WALLET_TOOL:-$BINDIR/bitcoin_silver-wallet}
BITCOIN_SILVERUTIL=${BITCOIN_SILVERQT:-$BINDIR/bitcoin_silver-util}
BITCOIN_SILVERQT=${BITCOIN_SILVERQT:-$BINDIR/qt/bitcoin_silver-qt}

[ ! -x $BITCOIN_SILVERD ] && echo "$BITCOIN_SILVERD not found or not executable." && exit 1

# Don't allow man pages to be generated for binaries built from a dirty tree
DIRTY=""
for cmd in $BITCOIN_SILVERD $BITCOIN_SILVERCLI $BITCOIN_SILVERTX $WALLET_TOOL $BITCOIN_SILVERUTIL $BITCOIN_SILVERQT; do
  VERSION_OUTPUT=$($cmd --version)
  if [[ $VERSION_OUTPUT == *"dirty"* ]]; then
    DIRTY="${DIRTY}${cmd}\n"
  fi
done
if [ -n "$DIRTY" ]
then
  echo -e "WARNING: the following binaries were built from a dirty tree:\n"
  echo -e $DIRTY
  echo "man pages generated from dirty binaries should NOT be committed."
  echo "To properly generate man pages, please commit your changes to the above binaries, rebuild them, then run this script again."
fi

# The autodetected version git tag can screw up manpage output a little bit
read -r -a BTCSVER <<< "$($BITCOIN_SILVERCLI --version | head -n1 | awk -F'[ -]' '{ print $6, $7 }')"

# Create a footer file with copyright content.
# This gets autodetected fine for bitcoin_silverd if --version-string is not set,
# but has different outcomes for bitcoin_silver-qt and bitcoin_silver-cli.
echo "[COPYRIGHT]" > footer.h2m
$BITCOIN_SILVERD --version | sed -n '1!p' >> footer.h2m

for cmd in $BITCOIN_SILVERD $BITCOIN_SILVERCLI $BITCOIN_SILVERTX $WALLET_TOOL $BITCOIN_SILVERUTIL $BITCOIN_SILVERQT; do
  cmdname="${cmd##*/}"
  help2man -N --version-string=${BTCSVER[0]} --include=footer.h2m -o ${MANDIR}/${cmdname}.1 ${cmd}
done

rm -f footer.h2m
