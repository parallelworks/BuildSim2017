# Swift accepts an existing rad and mat file and runs a rpict timelapse using Radiance-5.0.a.11

type file;


############################################
# ------ INPUT / OUTPUT DEFINITIONS -------#
############################################

# INPUTS

file rad 		<arg("rad","sample_inputs/geometry.rad")>;
file mat 		<arg("mat","sample_inputs/material.rad")>;

string fc       = arg("falsecolor","true");
string fc_max   = arg("falsecolor_max","5");

string sky      = arg("sky","+s");
string loc      = arg("loc","46 123 120");
string vt       = arg("viewtype","v");
string vs       = arg("viewsize","44.5 30.4");
string dim      = arg("dim","400 300");
string params   = arg("params","-ab 2 -ad 512 -as 20 -ar 64 -aa 0.2 -ps 2 -pt .05 -pj .9 -dj .7 -ds .15 -dt .05 -dc .75 -dr 3 -dp 512 -st .15 -lr 8 -lw .005");

string cams[]   = readData(arg("cams","sample_inputs/input_cams.txt"));
string runDays[] = readData(arg("day","sample_inputs/input_days.txt"));
string runTimes[] = readData(arg("time","sample_inputs/input_times.txt"));

# OUTPUTS
file outhtml 		<arg("outhtml","results/out.html")>;
file outtar 		<arg("outtar","results/out.tgz")>;
file outtab 		<arg("outtab","results/out.tab")>;

# WORKFLOW FILES
file utils[] 	    <FilesysMapper;location="model">;


##############################
# ---- APP DEFINITIONS ----- #
##############################

app (file rad) preRadiance (file geom, file utils[])
{
    bash "model/preRad.sh" @geom @rad;
}

app (file img,file tab,file out,file err) runRadiance (string day, string time, string cam, file rad, file  mat, string sky, string loc, string vt, string vs, string dim, string fc, string fc_max, string params, file utils[])
{
    bash "model/runSim.sh" day time cam @rad @mat sky loc vt vs dim fc fc_max params @img @tab stdout=@out stderr=@err;
}

app (file outgif,file outplot) postRadiance (file[string] r, file[string] rt, file utils[]){
	bash "model/postRad.sh" @outgif @outplot;
}

app (file outhtml, file outtar, file outtab) compileRadiance (file[string] g,file[string] p,file[string] rt, file utils[]){
	bash "model/compileRad.sh" @outhtml @outtar @outtab;
}


######################
# ---- WORKFLOW ---- #
######################

file[string] outgifs;
file[string] outplots;
file[string] rad_tabs_all;

foreach cam,c in cams {

    foreach runday,i in runDays {
    
        file[string] rad_imgs;
        file[string] rad_tabs;
        
        foreach runtime,j in runTimes {
        
            string fileid = strjoin(["radimg",toString(c),regexp(runday," ","-"),regexp(runtime," ","-")],"_");
            
            tracef("%s\n",fileid);
            
            file rad_img    <strcat("output/bmp/",fileid,".bmp")>;
            file rad_tab    <strcat("output/tab/",fileid,".tab")>;
            file rad_out    <strcat("output/out/",fileid,".out")>;
            file rad_err    <strcat("output/err/",fileid,".err")>;
            
            (rad_img,rad_tab,rad_out,rad_err) = runRadiance(runday,runtime,cam,rad,mat,sky,loc,vt,vs,dim,fc,fc_max,params,utils);
    
    		rad_imgs[fileid] = rad_img;
            rad_tabs[fileid] = rad_tab;
            rad_tabs_all[fileid] = rad_tab;
    
    	}
    
        # convert day images into video
        string fileid_day = strjoin(["radvid",toString(c),regexp(runday," ","-")],"_");
        
        file out_gif        <strcat("output/gif/",fileid_day,".gif")>;
        file out_plot       <strcat("output/png/",fileid_day,".png")>;
    	
    	(out_gif,out_plot) = postRadiance(rad_imgs,rad_tabs,utils);
    	
    	outgifs[fileid_day] = out_gif;
        outplots[fileid_day] = out_plot;
    
    }

}

(outhtml,outtar,outtab) = compileRadiance(outgifs,outplots,rad_tabs_all,utils);

