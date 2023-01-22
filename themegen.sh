#!/usr/bin/env bash

# themegen.sh: Given one fluxbox theme, generate a new one with a different
# base color.

# Check to see whether a given color is gray; if not, adjust according to the
# ratio with the new base color.
checkit (){
HEX=$1

RED=$(printf %d 0x$(echo $HEX | cut -c1-2))
GRN=$(printf %d 0x$(echo $HEX | cut -c3-4))
BLU=$(printf %d 0x$(echo $HEX | cut -c5-6))

# If any of these ratios is greater than the check limit, the color is not a shade
# of gray and will need to be changed.
RG=$(echo 100*$RED/$GRN | bc -l | cut -d. -f1)
GR=$(echo 100*$GRN/$RED | bc -l | cut -d. -f1)
RB=$(echo 100*$RED/$BLU | bc -l | cut -d. -f1)
BR=$(echo 100*$BLU/$RED | bc -l | cut -d. -f1)
BG=$(echo 100*$BLU/$GRN | bc -l | cut -d. -f1)
GB=$(echo 100*$GRN/$BLU | bc -l | cut -d. -f1)

if [[ $RG -gt $CST ]] || [[ $RB -gt $CST ]] || [[ $BG -gt $CST ]] || \
     [[ $GR -gt $CST ]] || [[ $BR -gt $CST ]] || [[ $GB -gt $CST ]]; then
	# Round off.
	NR=$(echo \($(echo $RRAT*$RED | bc) + 0.5\) / 1 | bc)
	NG=$(echo \($(echo $GRAT*$GRN | bc) + 0.5\) / 1 | bc)
	NB=$(echo \($(echo $BRAT*$BLU | bc) + 0.5\) / 1 | bc)
	# Good color check.
	[[ $NR -gt 255 ]] && NR=255
	[[ $NG -gt 255 ]] && NG=255
	[[ $NB -gt 255 ]] && NB=255
	# And get the new color in hex.
	NEWCOLOR=$(printf %X $NR | tr [:lower:] [:upper:])
	NEWCOLOR=$NEWCOLOR$(printf %X $NG | tr [:lower:] [:upper:])
	NEWCOLOR=$NEWCOLOR$(printf %X $NB | tr [:lower:] [:upper:])
	# Make the change.
	sed -i "s/$1/$NEWCOLOR/g" $2
fi
}

# For the xpm file, collect a list of colors to check.
getcolors (){
echo $1 working...
COLORS=$(mktemp /tmp/col-XXXXX)
# The first listed color is always represented by a space, so the main cut
# statement won't work.
grep '" ' $1 | cut -d' ' -f3 | tr -d \# | tr -d \" | tr -d \, | grep -v ^$ > $COLORS
grep "c #" $1 | cut -d' ' -f2 | tr -d \# | tr -d \" | tr -d \, | grep -v c$ >> $COLORS

while read -r color; do
	checkit $color $1
done < $COLORS

# Clean up.
rm -f $COLORS
}

[ -z $3 ] && echo Usage: ./themegen.sh old-theme-name new-theme-name new-theme-color && exit
INTHEME=$1
INDIR="$HOME/.fluxbox/styles/$INTHEME"
OTHEME=$2
ODIR="$HOME/.fluxbox/styles/$OTHEME"
OUTCOLOR=$(echo $3 | tr [:lower:] [:upper:])
MANIFEST=$(mktemp /tmp/themefiles-XXXXX)

CST="110"		# Ten percent tolerance; this seems to work pretty well.

[ -d "$ODIR" ] && echo New theme already at $ODIR. && exit
[ ! -d "$INDIR" ] && echo Existing theme not found at $INDIR. && exit

cp -r "$INDIR" "$ODIR"

# Base color and fade-to should be defined here.
INCOLOR=$(grep "toolbar.workspace.textColor" $INDIR/theme.cfg | cut -d\# -f2)
INACCENT=$(grep "menu.hilite.colorTo" $INDIR/theme.cfg | cut -d\# -f2)

INRED=$(printf %d 0x$(echo $INCOLOR | cut -c1-2))
INGRN=$(printf %d 0x$(echo $INCOLOR | cut -c3-4))
INBLU=$(printf %d 0x$(echo $INCOLOR | cut -c5-6))

OUTRED=$(printf %d 0x$(echo $OUTCOLOR | cut -c1-2))
OUTGRN=$(printf %d 0x$(echo $OUTCOLOR | cut -c3-4))
OUTBLU=$(printf %d 0x$(echo $OUTCOLOR | cut -c5-6))

# Calculating the new fade-to color.
NORED=$(echo \($(echo $OUTRED*1.20 | bc -l) + 0.5\) / 1 | bc)
NOGRN=$(echo \($(echo $OUTGRN*1.20 | bc -l) + 0.5\) / 1 | bc)
NOBLU=$(echo \($(echo $OUTBLU*1.20 | bc -l) + 0.5\) / 1 | bc)
# Going over 255 causes problems.
[ $NORED -gt 255 ] && NORED=255
[ $NOGRN -gt 255 ] && NOGRN=255
[ $NOBLU -gt 255 ] && NOBLU=255

NORED=$(printf %X $NORED)
NOGRN=$(printf %X $NOGRN)
NOBLU=$(printf %X $NOBLU)
ACCENT=$NORED$NOGRN$NOBLU

# Change the theme file: title, main color, and fade-to color.
sed -i "s/$INTHEME/$OTHEME/g" $ODIR/theme.cfg
sed -i "s/$INCOLOR/$OUTCOLOR/g" $ODIR/theme.cfg
sed -i "s/$INACCENT/$ACCENT/g" $ODIR/theme.cfg
# Correct attribution
sed -i "s/made: K. Eugene Carlson/made: $(whoami) - automatically generated from $INTHEME with themegen.sh/g" $ODIR/theme.cfg

# Determining the differences between the RGB of the old and new base colors.
RRAT=$(echo $OUTRED/$INRED | bc -l)
GRAT=$(echo $OUTGRN/$INGRN | bc -l)
BRAT=$(echo $OUTBLU/$INBLU | bc -l)

# Get the list of pixmaps
find $ODIR/pixmaps -type f > $MANIFEST

# Actually perform the xpm conversions.
while read -r file; do
	getcolors $file
done < $MANIFEST

echo
echo $OTHEME\: $OUTCOLOR, $ACCENT
echo Done.
echo
