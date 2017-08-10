# Urban Analysis Parameter Sweep

type file;

############################################
# ------ INPUT / OUTPUT DEFINITIONS -------#
############################################

# workflow inputs
# comment this line out when running under dakota
# file params         <arg("paramFile","params.run")>; 

# add models
file kpi            <"models/kpi.json">;
file[] geometry     <Ext;exec="utils/mapper.sh",root="models/geometry">;
file[] view         <Ext;exec="utils/mapper.sh",root="models/view">;
file[] mexdex       <Ext;exec="utils/mapper.sh",root="models/mexdex">;
# file[] openfoam   <Ext;exec="utils/mapper.sh",root="models/openfoam">;

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

app (file[] geomout, file paramsout, file constraintout, file so, file se) generateGeometry (string casestring,string geomLocation,file[] geom)
{
  bash "models/geometry/genMesh.sh" casestring @paramsout geomLocation @constraintout stdout=@so stderr=@se;
}

app (file viewmetrics,file[] viewimages, file so, file se) viewAnalysis (string geomLocation,file[] casegeometry,string imageLocation, file[] view, file kpi, file[] mexdex)
{
  bash "models/view/runView.sh"  geomLocation @viewmetrics imageLocation @kpi stdout=@so stderr=@se;
}

app (file comfortmetrics,file[] viewimages, file so, file se) comfortAnalysis (string geomLocation,file[] casegeometry,string imageLocation, file caseParams, file[] view, file[] mexdex)
{
  bash "models/openfoam/runComfort.sh"  geomLocation @comfortmetrics imageLocation @caseParams stdout=@so stderr=@se;
}

app (file outcsv, file outhtml, file so, file se) postProcess (file[] t, file[] c, string rpath, file caselist, file kpi, file[] mexdex) {
  bash "models/mexdex/postprocess.sh" filename(outcsv) filename(outhtml) rpath @kpi stdout=filename(so) stderr=filename(se);
}


######################
# ---- WORKFLOW ---- #
######################

file caselist <"cases.list">;

# comment this line out when running under dakota
# caselist = prepInputs(params,mexdex);

string[] cases = readData(caselist);

tracef("\n%i Cases in Simulation\n\n",length(cases));

file[] metrics;
file[] constraints;
foreach caseString,i in cases{

  #trace(i,caseString);

  # generate the geometry step file
  string geomLocation =strcat(casedir,"_",i,"/geometry");
  file caseGeometry[] <FilesysMapper;location=geomLocation>;
  file caseParams     <strcat(casedir,"_",i,"/params.txt")>;
  file geomConstraint <strcat(casedir,"_",i,"/area.txt")>;
  file go 	          <strcat("logs/case_",i,"/generateGeometry.out")>;
	file ge         	  <strcat("logs/case_",i,"/generateGeometry.err")>;
  (caseGeometry,caseParams,geomConstraint,go,ge) = generateGeometry(caseString,geomLocation,geometry);
  constraints[i] = geomConstraint;
  
  # run the view analysis
  file viewMetrics    <strcat(outdir,"metrics/case_",i,".csv")>;
  string imageLocation=strcat(casedir,"_",i);
  file viewImages[]   <FilesysMapper;location=imageLocation>;
  file vo 	          <strcat("logs/case_",i,"/viewAnalysis.out")>;
	file ve         	  <strcat("logs/case_",i,"/viewAnalysis.err")>;
  (viewMetrics,viewImages,vo,ve) = viewAnalysis(geomLocation,caseGeometry,imageLocation,view,kpi,mexdex);
  metrics[i] = viewMetrics;

  # run the comfort analysis
  #file comfortMetrics    <strcat(outdir,"metrics/case_",i,".csv")>;
  #string comfortLocation=strcat(casedir,"_",i);
  #file comfortImages[]   <FilesysMapper;location=comfortLocation>;
  #file co 	          <strcat("logs/case_",i,"/comfortAnalysis.out")>;
	#file ce         	  <strcat("logs/case_",i,"/comfortAnalysis.err")>;
  #(comfortMetrics,comfortImages,co,ce) = comfortAnalysis(geomLocation,caseGeometry,comfortLocation,caseParams,openfoam,mexdex);
  #metrics[i] = comfortMetrics;

}

file spout <"logs/post.out">;
file sperr <"logs/post.err">;
(outcsv,outhtml,spout,sperr) = postProcess(metrics, constraints, path, caselist, kpi, mexdex);

