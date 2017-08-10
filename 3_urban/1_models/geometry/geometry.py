#!/usr/bin/env python

import sys
import os
import shutil
import math
import heapq
import tempfile
import datetime

import numpy
import stl as meshstl
from stl import mesh
import yaml

from onshape import Client

CONFIG_PATH = sys.argv[1]
if not os.path.isabs(CONFIG_PATH):
    CONFIG_PATH = os.path.abspath(CONFIG_PATH)
CASE_DIR = os.path.dirname(CONFIG_PATH)

EMAIL = 'ONSHAPE_EMAIL'
PASSWORD = 'ONSHAPE_PASS'
KEY = None

# hard-coding the ids is much faster than searching for them
DOCUMENT_ID = "DOCUMENT_ID"
WORKSPACE_ID = "WORKSPACE_ID"

DOCUMENT_NAME = "Parametric Massings"
ELEMENT_NAME = "massing"
SUBELEMENT_NAME = ""
PARTS = [] # use for individual stl exporting
UNITS = "meter"
EXPORT_STL = False
EXPORT_STEP = True
EXPORT_IMAGE = False


def geo_parameters(config):
    if not os.path.isabs(config):
        config = os.path.abspath(config)

    with open(config, 'r') as f:
        content = f.read()

    all_params = yaml.load(content)
    geo_params = {}
    
    print all_params
    
    # use this to filter params
    #geo_variables = [
    #    "building1_height",
    #]
    #for var in geo_variables:
    #    geo_params[var.lower()] = all_params[var]
    
    return all_params


def find_document(client, document_name):
    for document in client.documents(document_name)['items']:
        if document['name'] == document_name:
            document_id = document['id']
            workspace_id = document['defaultWorkspace']['id']
            return document_id, workspace_id
    return None, None


def copy_workspace(client, document_id, workspace_id, workspace_name):
    workspace = client.copyWorkspace(document_id, workspace_id, workspace_name, 
        'Temp')
    document_id = workspace['newDocumentId']
    workspace_id = workspace['newWorkspaceId']
    return document_id, workspace_id


def get_element_id(client, document_id, workspace_id, element_name, 
        subelement_name):
    element_id = None
    subelement_id = None

    for element in client.elements(document_id, workspace_id):
        if element['name'] == element_name:
            element_id = element['id']

        if element['name'] == subelement_name:
            subelement_id = element['id']

    return element_id, subelement_id


def get_serialization_version(client, document_id, workspace_id, element_id):
    all_features = client.features(document_id, workspace_id, element_id)
    serialization_version = all_features['serializationVersion']
    return serialization_version


def get_source_microversion(client, document_id, workspace_id, element_id):
    all_features = client.features(document_id, workspace_id, element_id)
    source_microversion = all_features['sourceMicroversion']
    return source_microversion


def get_parts(client, document_id, workspace_id, element_id):
    return client.getParts(document_id, workspace_id, element_id)


def get_part_ids(client, document_id, workspace_id, element_id):
    part_ids = {}
    for part in get_parts(client, document_id, workspace_id, element_id):
        part_ids[part['name']] = part['partId']
    return part_ids


def get_features(client, document_id, workspace_id, element_id):
    all_features = client.features(document_id, workspace_id, element_id)

    features = {}
    feature_ids = {}
    for feature in all_features['features']:
        if feature['typeName'] == 'BTMFeature':
            if feature['message']['featureType'] == 'assignVariable':
                features[
                    feature['message']['parameters'][0]['message']['value']
                ] = feature
                feature_ids[
                    feature['message']['parameters'][0]['message']['value']
                ] = feature['message']['featureId']

    return features, feature_ids


def edit_feature(client, features, feature_ids, document_id, workspace_id, element_id, param_name, 
        param_value, serialization_version, source_microversion):

    features[param_name]['message']['parameters'][1]['message']['expression'] = \
        param_value

    feature = {
        'feature': features[param_name],
        'serializationVersion': serialization_version,
        'sourceMicroversion': source_microversion
    }

    feature_id = feature_ids[param_name]

    client.editFeature(document_id, workspace_id, element_id, feature_id, 
        feature)


def edit_features(client, features, feature_ids, document_id, workspace_id, element_id, parameters,
        serialization_version, source_microversion):
    for param_name, param_value in parameters.items():
        edit_feature(client, features, feature_ids, document_id, workspace_id, element_id, param_name,
            param_value, serialization_version, source_microversion)


def _remove_file_if_exists(path):
    if os.path.isfile(path):
        os.remove(path)


def export_stl_part(client, document_id, workspace_id, element_id, part_id, 
        part_name, stl_path, units='meter'):
    _remove_file_if_exists(stl_path)

    stl = client.exportSTLpart(document_id, workspace_id, element_id, part_id,
        units).split('\n')
    stl[0] = stl[0].replace('Onshape', part_name)
    stl[-2] = stl[-2].replace('Onshape', part_name)

    with open(stl_path, 'w') as f:
        f.write('\n'.join(stl))

def export_step_part(client, document_id, workspace_id, element_id, step_path, units='meter'):
    _remove_file_if_exists(step_path)

    step = client.exportSTEPpart(document_id, workspace_id, element_id,units).split('\n')
        
    with open(step_path, 'w') as f:
        f.write('\n'.join(step))
        
def export_image(client, document_id, workspace_id, element_id, path):
    img = client.exportIMG(document_id, workspace_id, element_id)
    with open(path, 'wb') as f:
        f.write(img)


def delete_workspace(client, document_id, workspace_id):
    client.deleteWorkspace(document_id, workspace_id)


def main():

    print "Starting Onshape Process..."
    print ""
    sys.stdout.flush()
    
    print "Extracting Parameters"
    sys.stdout.flush()
    parameters = geo_parameters(CONFIG_PATH)

    print "Establishing Client"
    sys.stdout.flush()
    client = Client(EMAIL, PASSWORD, two_factor_key=KEY)

    #print "Finding Document"
    #sys.stdout.flush()
    #orig_document_id, orig_workspace_id = find_document(client, DOCUMENT_NAME)
    
    orig_document_id = DOCUMENT_ID
    orig_workspace_id = WORKSPACE_ID

    workspace_name = 'temp model - ' + str(datetime.datetime.now())

    print "Copying Workspace"
    sys.stdout.flush()
    document_id, workspace_id =  copy_workspace(client, orig_document_id, orig_workspace_id, workspace_name)
    #document_id = orig_document_id
    #workspace_id = orig_workspace_id

    print "Getting Elements"
    sys.stdout.flush()
    element_id, subelement_id = get_element_id(client, document_id, 
        workspace_id, ELEMENT_NAME, SUBELEMENT_NAME)

    features, feature_ids = get_features(client, document_id, workspace_id, 
        element_id)

    serialization_version = get_serialization_version(client, document_id, 
        workspace_id, element_id)

    source_microversion = get_source_microversion(client, document_id, 
        workspace_id, element_id)
        
    print "Editing Features"
    sys.stdout.flush()
    edit_features(client, features, feature_ids, document_id, workspace_id, 
        element_id, parameters, serialization_version, source_microversion)

    print "Exporting File"
    if EXPORT_STL:
        parts = get_parts(client, document_id, workspace_id, element_id)
        part_ids = get_part_ids(client, document_id, workspace_id, element_id)
        for part_name, part_id in part_ids.items():
            stl_path = os.path.join(CASE_DIR, 'run', 'constant', 'triSurface', 
                part_name + '.stl')
            export_stl_part(client, document_id, workspace_id, element_id, part_id,
                part_name, stl_path)
    
    if EXPORT_STEP:
            step_path=sys.argv[2]
            export_step_part(client, document_id, workspace_id, element_id, step_path)

    if EXPORT_IMAGE:
        image_path = os.path.join(CASE_DIR, 'onshape.png')
        export_image(client, document_id, workspace_id, element_id, image_path)
    
    print "Deleting Workspace"
    delete_workspace(client, document_id, workspace_id)

    print ""
    print "Onshape Geometry Generation Complete."
    print ""

if __name__ == '__main__':
    main()
