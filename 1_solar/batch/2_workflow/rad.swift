# simple swift workflow to execute radiance batch from csv file

type file;

# ------ INPUT / OUTPUT DEFINITIONS -------#

file caselist       <arg("cases","sample_inputs/cases.csv")>;
file geometry       <arg("geometry","sample_inputs/geometry.obj")>;
file result         <arg("result","result.tgz")>;

file model[] 	    <FilesysMapper;location="model">;

# ---- APP DEFINITIONS ----- #

app (file outimg,file out,file err) runRadiance (string params[], file geometry, file model[])
{
    bash "model/runSim.sh" params @geometry @outimg stdout=@out stderr=@err;
}
app (file out) postRadiance (file imgs[],file model[])
{
    bash "model/postSim.sh" @out;
}

# ---- WORKFLOW ---- #

string cases[]      = readData(caselist);
tracef("\n%i Cases in Simulation\n\n",length(cases)-1);

file imgs[];
foreach c, i in cases {
    if (i!=0){
    
        string header = cases[0];
        string params[] = strsplit(c,",");
        
        trace(i,c);
        
        file img    <strcat("results/out_",pad(3,i),".png")>;
        file so     <strcat("logs/",i,".out")>;
        file se     <strcat("logs/",i,".err")>;
        
        (img,so,se) = runRadiance(params,geometry,model);
        
        imgs[i] = img;
        
    }
}

result = postRadiance(imgs,model);
