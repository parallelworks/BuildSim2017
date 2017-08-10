# Interior Thermal Comfort Parameter Sweep

type file;

############################################
# ------ INPUT / OUTPUT DEFINITIONS -------#
############################################

# workflow inputs
# comment this line out when running under dakota
file params         <arg("paramFile","params.run")>; 

# add models
file kpi            <"models/kpi.json">;
file[] geometry     <Ext;exec="utils/mapper.sh",root="models/geometry">;
file[] openfoam     <Ext;exec="utils/mapper.sh",root="models/openfoam">;
file[] mexdex       <Ext;exec="utils/mapper.sh",root="models/mexdex">;

# workflow outputs
file outhtml        <arg("html","results/output.html")>;
file outcsv         <arg("csv","results/output.csv")>;

# other inputs
string outdir      = "results/";
string casedir     = strcat(outdir,"case");
string path        = toString(@java("java.lang.System","getProperty","user.dir"));


##############################
# ---- APP DEFINITIONS ----- #
##############################

app (file out) prepInputs (file params, file s[])
{
  python "models/mexdex/prepInputs.py" @params @out;
}

app (file[] geomout, file paramsout, file so, file se) generateGeometry (string casestring,string geomLocation,file[] geom)
{
  bash "models/geometry/genGeometry.sh" casestring @paramsout geomLocation stdout=@so stderr=@se;
}

app (file comfortmetrics,file[] viewimages, file so, file se) comfortAnalysis (string geomLocation,file[] casegeometry,string imageLocation, file caseParams, file[] view, file kpi, file[] mexdex)
{
  bash "models/openfoam/runComfort.sh"  geomLocation @comfortmetrics imageLocation @caseParams @kpi stdout=@so stderr=@se;
}

app (file outcsv, file outhtml, file so, file se) postProcess (file[] t, string rpath, file caselist, file kpi, file[] mexdex) {
  bash "models/mexdex/postprocess.sh" filename(outcsv) filename(outhtml) rpath @kpi stdout=filename(so) stderr=filename(se);
}

######################
# ---- WORKFLOW ---- #
######################

file caselist <"cases.list">;

# comment this line out when running under dakota
caselist = prepInputs(params,mexdex);

string[] cases = readData(caselist);

tracef("\n%i Cases in Simulation\n\n",length(cases));

file[] metrics;
foreach caseString,i in cases{

  #trace(i,caseString);

  # generate the geometry stl file
  string geomLocation =strcat(casedir,"_",i,"/geometry");
  file caseGeometry[] <FilesysMapper;location=geomLocation>;
  file caseParams     <strcat(casedir,"_",i,"/params.txt")>;
  file go 	          <strcat("logs/case_",i,"/generateGeometry.out")>;
	file ge         	  <strcat("logs/case_",i,"/generateGeometry.err")>;
  (caseGeometry,caseParams,go,ge) = generateGeometry(caseString,geomLocation,geometry);
  
  # run the comfort analysis
  file comfortMetrics    <strcat(outdir,"metrics/case_",i,".csv")>;
  string comfortLocation=strcat(casedir,"_",i);
  file comfortImages[]   <FilesysMapper;location=comfortLocation>;
  file co 	          <strcat("logs/case_",i,"/comfortAnalysis.out")>;
	file ce         	  <strcat("logs/case_",i,"/comfortAnalysis.err")>;
  (comfortMetrics,comfortImages,co,ce) = comfortAnalysis(geomLocation,caseGeometry,comfortLocation,caseParams,openfoam,kpi,mexdex);

  metrics[i] = comfortMetrics;
  
}

file spout <"logs/post.out">;
file sperr <"logs/post.err">;
(outcsv,outhtml,spout,sperr) = postProcess(metrics, path, caselist, kpi, mexdex);

