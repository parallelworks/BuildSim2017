# BuildSim Solar Workflows

Start a local cluster with a few workers running

```
pworks cluster 2
```

Test, run and deploy the radiance batch workflow:

```
cd batch

# test the radiance model 
cd model
./test.sh

# test the batch radiance workflow on the local cluster
cd workflow
swift rad.swift

# if all working properly, clean up the files
./clean.sh

# deploy to Parallel Works
cd ../
pworks deploy <apikey> workflow radiance_batch_v1

# make any needed edits to the workflow 

# scale simulations on the cloud

```
