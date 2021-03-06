#!/bin/csh -fe
# RCSid: $Id: falsecolor.csh,v 2.20 2009/05/27 15:38:29 greg Exp $
#
# Create false color image with legend
#
# Added user-definable legend 2004/01/20 Rob Guglielmetti
#
# Added -cz and -mask options - Thomas Bleicher, March 2010

onintr quit
set td=`mktemp -d /tmp/fc.XXXXXX`
set mult=179
set label=Nits
set delta=0.5
set scale=1000
set decades=0
set redv='def_red(v)'
set grnv='def_grn(v)'
set bluv='def_blu(v)'
set ndivs=8
set picture='-'
set cpict=
set loff=0
set legwidth=100
set legheight=200
set mask=0
while ($#argv > 0)
	switch ($argv[1])
	case -lw:
		shift argv
		set legwidth="$argv[1]"
		breaksw
	case -lh:
		shift argv
		set legheight="$argv[1]"
		breaksw
	case -m:
		shift argv
		set mult="$argv[1]"
		breaksw
	case -s:
		shift argv
		set scale="$argv[1]"
		if ("$scale" =~ [aA]*) set needfile
		breaksw
	case -l:
		shift argv
		set label="$argv[1]"
		breaksw
	case -log:
		shift argv
		set decades=$argv[1]
		breaksw
	case -r:
		shift argv
		set redv="$argv[1]"
		breaksw
	case -g:
		shift argv
		set grnv="$argv[1]"
		breaksw
	case -b:
		shift argv
		set bluv="$argv[1]"
		breaksw
	case -spec:
		set redv='old_red(v)'
		set grnv='old_grn(v)'
		set bluv='old_blu(v)'
		breaksw
        case -mask:
		shift argv
		set maskvalue="$argv[1]"
                breaksw
	case -i:
		shift argv
		set picture="$argv[1]"
		breaksw
	case -p:
		shift argv
		set cpict="$argv[1]"
		breaksw
	case -ip:
	case -pi:
		shift argv
		set picture="$argv[1]"
		set cpict="$argv[1]"
		breaksw
	case -cl:
		set docont=a
		set loff=12
		breaksw
	case -cb:
		set docont=b
		set loff=13
		breaksw
        case -cz:
		set docont=a
		set loff=2
                set delta=0.0
		breaksw
	case -e:
		set doextrem
		set needfile
		breaksw
	case -n:
		shift argv
		set ndivs="$argv[1]"
		breaksw
	default:
		echo bad option "'$argv[1]'"
		exit 1
	endsw
	shift argv
end
if ($?needfile && "$picture" == '-') then
	cat > $td/picture
	set picture=$td/picture
endif
if ("$scale" =~ [aA]*) then
	set LogLmax=`phisto $picture | tail -2 | sed -n '1s/	[0-9]*$//p'`
	set scale=`ev "$mult/179*10^$LogLmax"`
endif
cat > $td/pc0.cal <<_EOF_
PI : 3.14159265358979323846 ;
scale : $scale ;
mult : $mult ;
ndivs : $ndivs ;

or(a,b) : if(a,a,b);
EPS : 1e-7;
neq(a,b) : if(a-b-EPS,1,b-a-EPS);
btwn(a,x,b) : if(a-x,-1,b-x);
clip(x) : if(x-1,1,if(x,x,0));
frac(x) : x - floor(x);
boundary(a,b) : neq(floor(ndivs*a+$delta),floor(ndivs*b+$delta));

old_red(x) = 1.6*x - .6;
old_grn(x) = if(x-.375, 1.6-1.6*x, 8/3*x);
old_blu(x) = 1 - 8/3*x;

interp_arr2(i,x,f):(i+1-x)*f(i)+(x-i)*f(i+1);
interp_arr(x,f):if(x-1,if(f(0)-x,interp_arr2(floor(x),x,f),f(f(0))),f(1));
def_redp(i):select(i,0.18848,0.05468174,
0.00103547,8.311144e-08,7.449763e-06,0.0004390987,0.001367254,
0.003076,0.01376382,0.06170773,0.1739422,0.2881156,0.3299725,
0.3552663,0.372552,0.3921184,0.4363976,0.6102754,0.7757267,
0.9087369,1,1,0.9863);
def_red(x):interp_arr(x/0.0454545+1,def_redp);
def_grnp(i):select(i,0.0009766,2.35501e-05,
0.0008966244,0.0264977,0.1256843,0.2865799,0.4247083,0.4739468,
0.4402732,0.3671876,0.2629843,0.1725325,0.1206819,0.07316644,
0.03761026,0.01612362,0.004773749,6.830967e-06,0.00803605,
0.1008085,0.3106831,0.6447838,0.9707);
def_grn(x):interp_arr(x/0.0454545+1,def_grnp);
def_blup(i):select(i,0.2666,0.3638662,0.4770437,
0.5131397,0.5363797,0.5193677,0.4085123,0.1702815,0.05314236,
0.05194055,0.08564082,0.09881395,0.08324373,0.06072902,
0.0391076,0.02315354,0.01284458,0.005184709,0.001691774,
2.432735e-05,1.212949e-05,0.006659406,0.02539);
def_blu(x):interp_arr(x/0.0454545+1,def_blup);

isconta = if(btwn(0,v,1),or(boundary(vleft,vright),boundary(vabove,vbelow)),-1);
iscontb = if(btwn(0,v,1),btwn(.4,frac(ndivs*v),.6),-1); 

ra = 0;
ga = 0;
ba = 0;

in = 1;

ro = if(in,clip($redv),ra);
go = if(in,clip($grnv),ga);
bo = if(in,clip($bluv),ba);
_EOF_
cat > $td/pc1.cal <<_EOF_
norm : mult/scale/le(1);

v = map(li(1)*norm);

vleft = map(li(1,-1,0)*norm);
vright = map(li(1,1,0)*norm);
vabove = map(li(1,0,1)*norm);
vbelow = map(li(1,0,-1)*norm);

map(x) = x;

ra = ri(nfiles);
ga = gi(nfiles);
ba = bi(nfiles);
_EOF_
set pc0args=(-f $td/pc0.cal)
set pc1args=(-f $td/pc1.cal)
if ($?docont) then
	set pc0args=($pc0args -e "in=iscont$docont")
endif
if ("$cpict" == "") then
	set pc1args=($pc1args -e 'ra=0;ga=0;ba=0')
else if ("$cpict" == "$picture") then
	set cpict=
endif
if ("$decades" != "0") then
	set pc1args=($pc1args -e "map(x)=if(x-10^-$decades,log10(x)/$decades+1,0)")
	set imap="imap(y)=10^((y-1)*$decades)"
else
	set imap="imap(y)=y"
endif
if ( $legwidth > 20 && $legheight > 40 ) then
        pcomb $pc0args -e 'v=(y+'"$delta"')/yres;vleft=v;vright=v' \
		-e 'vbelow=(y-(1-'"$delta"'))/yres;vabove=(y+1+'"$delta"')/yres' \
		-x $legwidth -y $legheight > $td/scol.hdr
        
        if ( "$delta" == "0.5" ) then
            set legvalues=`cnt $ndivs | rcalc -e '$1='"($scale)*imap(($ndivs-.5-"'$1'")/$ndivs)" -e "$imap"`
        else
            set ndivs_1=`ev "$ndivs+1"`
            set legvalues=`cnt $ndivs_1 | rcalc -e '$1='"($scale)*imap(($ndivs-"'$1'")/$ndivs)" -e "$imap"`
        endif

        ( echo "$label"; echo "$legvalues" | tr " " "\n" \
                | sed -e 's/\(\.[0-9][0-9][0-9]\)[0-9]*/\1/' ) \
	| psign -s -.15 -cf 1 1 1 -cb 0 0 0 \
		-h `ev "floor($legheight/$ndivs+$delta)"` > $td/slab.hdr

else
	set legwidth=0
	set legheight=0
	(echo "" ; echo "-Y 1 +X 1" ; echo "aaa" ) > $td/scol.hdr
	cp $td/scol.hdr $td/slab.hdr

endif

if ( $?doextrem ) then
	pextrem -o $picture > $td/extrema
	set minpos=`sed 2d $td/extrema | rcalc -e '$2=$2;$1=$1+'"$legwidth"`
	set minval=`rcalc -e '$1=($3*.27+$4*.67+$5*.06)*'"$mult" $td/extrema | sed -e 2d -e 's/\(\.[0-9][0-9][0-9]\)[0-9]*/\1/'`
	set maxpos=`sed 1d $td/extrema | rcalc -e '$2=$2;$1=$1+'"$legwidth"`
	set maxval=`rcalc -e '$1=($3*.27+$4*.67+$5*.06)*'"$mult" $td/extrema | sed -e 1d -e 's/\(\.[0-9][0-9][0-9]\)[0-9]*/\1/'`
	psign -s -.15 -a 2 -h 16 $minval > $td/minv.hdr
	psign -s -.15 -a 2 -h 16 $maxval > $td/maxv.hdr
	pcomb $pc0args $pc1args $picture $cpict \
		| pcompos $td/scol.hdr 0 0 \
			+t .1 "\!pcomb -e 'lo=1-gi(1)' $td/slab.hdr" \
			`ev 2 $loff-1` -t .5 $td/slab.hdr 0 $loff \
		        - $legwidth 0 $td/minv.hdr $minpos $td/maxv.hdr $maxpos > $td/tmp_fc.hdr
else
	pcomb $pc0args $pc1args $picture $cpict \
		| pcompos $td/scol.hdr 0 `ev "2-4*$delta"` \
			+t .1 "\!pcomb -e 'lo=1-gi(1)' $td/slab.hdr" \
			`ev 2 $loff-1` -t .5 $td/slab.hdr 0 $loff \
			- $legwidth 0 > $td/tmp_fc.hdr
endif

## apply mask or print image to stdout
if ( $?maskvalue ) then
        set maskvalue=`ev $maskvalue/$mult`
        set bgv=`ev $maskvalue+1`
        pcompos -b $bgv $bgv $bgv $picture $legwidth 0 > $td/mask.hdr
        pcomb -e 'ro=if(li(2)-'"$maskvalue"',ri(1),0);go=if(li(2)-'"$maskvalue"',gi(1),0);bo=if(li(2)-'"$maskvalue"',bi(1),0);' $td/tmp_fc.hdr $td/mask.hdr
else
        cat $td/tmp_fc.hdr
endif

quit:
rm -rf $td
