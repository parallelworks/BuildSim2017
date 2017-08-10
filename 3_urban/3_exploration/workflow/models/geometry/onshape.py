import requests
import json
import bx
import time
import sys

import numpy
from stl import mesh
import tempfile

class Client():
    '''Call Onshape APIs by logging in with username and password.'''

    def __init__(self, email, password, two_factor_key=None):
        '''
        Creates a new Client instance.

        Args:
            email (str): Email address
            password (str): Password
        '''

        #self.api = 'https://partner.dev.onshape.com/api'
        self.api = 'https://cad.onshape.com/api'
        self.cache = bx.Db()
        self.session = requests.Session()
        self.credentials = {
            'email': email,
            'password': password
        }
        self.headers = {
            'Content-Type': 'application/json'
        }

        if two_factor_key:
            self.credentials['totp'] = two_factor_key

    def __clear(self):
        '''Clears the cache.'''

        self.cache.clear()

    def __auth(self):
        '''
        Checks if a user is authenticated; logs them in if not.

        Returns:
            dict: Session data

        Raises:
            requests.exceptions.HTTPError: If page is not found, server error,
                or 2FA key not provided
        '''

        try:
            return self.cache.get('session')
        except KeyError:
            req = self.session.post(self.api + '/users/session',
                                    data=json.dumps(self.credentials),
                                    headers=self.headers)

            req.raise_for_status()
            data = json.loads(req.text)
            self.userId = data['id']
            self.cache.put('session', data)
            return data

    def user(self):
        '''
        Get information of currently logged in user.

        Returns:
            dict: User account into

        Raises:
            requests.exceptions.HTTPError: If page is not found or server error
        '''

        return self.__auth()

    def documents(self,search):
        try:
            self.cache.get('session')
        except KeyError:
            self.__auth()

        req = self.session.get(self.api + '/documents?q='+search)
        req.raise_for_status()
        data = json.loads(req.text)
        return data

    def elements(self, did, wid):
        try:
            self.cache.get('session')
        except KeyError:
            self.__auth()

        req = self.session.get(self.api + "/documents/d/" + did + "/w/" + wid + "/elements")
        req.raise_for_status()

        data = json.loads(req.text)
        return data

    def features(self, did, wid, eid):
        try:
            self.cache.get('session')
        except KeyError:
            self.__auth()

        req = self.session.get(self.api + "/partstudios/d/" + did + "/w/" + wid + "/e/" + eid + "/features?")
        req.raise_for_status()

        data = json.loads(req.text)
        return data

    def editFeature(self, did, wid, eid, fid, newfeature):
        try:
            self.cache.get('session')
        except KeyError:
            self.__auth()

        req = self.session.post(self.api + "/partstudios/d/" + did + "/w/" + wid + "/e/" + eid + "/features/featureid/" + fid,
                                    data=json.dumps(newfeature),
                                    headers=self.headers)
                                    
        req.raise_for_status()

        data = json.loads(req.text)
        return data

    def exportSTLstudio(self, did, wid, eid):
        try:
            self.cache.get('session')
        except KeyError:
            self.__auth()

        req = self.session.get(self.api + "/partstudios/d/" + did + "/w/" + wid + "/e/" + eid + "/stl")
        req.raise_for_status()

        data = req.text
        return data

    def getParts(self, did, wid, eid):
        try:
            self.cache.get('session')
        except KeyError:
            self.__auth()

        req = self.session.get(self.api + "/parts/d/" + did + "/w/" + wid + "/e/" + eid)
        req.raise_for_status()
        
        data = json.loads(req.text)
        return data

    def exportSTLpart(self, did, wid, eid, pid, units):
        try:
            self.cache.get('session')
        except KeyError:
            self.__auth()

        req = self.session.get(self.api + "/parts/d/" + did + "/w/" + wid + "/e/" + eid + "/partid/"+pid+"/stl?units="+units)
        resp = req.raise_for_status()

        data = req.text
        return data

    def exportSTEPpart(self, did, wid, eid, units):
        try:
            self.cache.get('session')
        except KeyError:
            self.__auth()

        data = {
            "elementId":eid,
            "flattenAssemblies":"false",
            "formatName":"STEP",
            "grouping":"true",
            "partIds":"",
            "storeInDocument":"false",
            "versionString":"",
            "yAxisIsUp":"false",
            "importInBackground": "true"
        }
        
        req = self.session.post(self.api + "/documents/" + did + "/workspaces/" + wid + "/translate",
                                    data=json.dumps(data),
                                    headers=self.headers)
        resp = req.raise_for_status()
        data = json.loads(req.text)

        # get the translation status
        count = 0
        while count < 10:
            #print "calling",count
            url = self.api+"/translations/"+data['translationId']
            req = self.session.get(url)
            resp = req.raise_for_status()
            dataNew = json.loads(req.text)
            if dataNew['requestState'] == "ACTIVE":
                count = count + 1
                time.sleep(1)
            elif dataNew['requestState'] == "DONE":
                break
            elif dataNew['requestState'] == "FAILED":
                print "translate request failed"
                sys.exit(1)
        else:
           print count, " translate request failed"
           sys.exit(1)

        url = self.api+"/documents/d/"+did+"/foreigndata/"+dataNew['resultExternalDataIds'][0]
        req = self.session.get(url)
        resp = req.raise_for_status()
        data = req.text
        
        return data

    def copyWorkspace(self, did, wid, newName, label=None):
        try:
            self.cache.get('session')
        except KeyError:
            self.__auth()
        
        req = self.session.post(self.api + "/documents/" + did + "/workspaces/" + wid + "/copy",
                                    data=json.dumps({"newName": newName,"isPublic": "true"}),
                                    headers=self.headers)
                                    
        req.raise_for_status()
        saved_text=req.text
        
        # if label defined get label id and apply to new document
        if label != None:
            req = self.session.get(self.api + "/labels/users/" + self.userId + "?all=true")
            req.raise_for_status()
            data = json.loads(req.text)
            for l in data["items"]:
                if l['name'] == label:
                    req = self.session.post(self.api + "/labels/" + l['id'] + "/uses/documents",
                                                data=json.dumps({"documentIds":[json.loads(saved_text)['newDocumentId']],"labelId": l['id']}),
                                                headers=self.headers)
                    req.raise_for_status()

        data = json.loads(saved_text)
        return data

    def deleteWorkspace(self, did, wid):
        try:
            self.cache.get('session')
        except KeyError:
            self.__auth()
        
        req = self.session.delete(self.api + "/documents/" + did + "?forever=true")
        req.raise_for_status()
        
        return "Complete"

    def getMassProperties(self, did, wid, eid, pid):
        try:
            self.cache.get('session')
        except KeyError:
            self.__auth()

        req = self.session.get(self.api + "/parts/d/" + did + "/w/" + wid + "/e/" + eid + "/partid/"+pid+"/massproperties")
        req.raise_for_status()

        data = json.loads(req.text)
        return data

    def getPartCenterPoint(self, did, wid, eid, pid):
        try:
            self.cache.get('session')
        except KeyError:
            self.__auth()
        req = self.session.get(self.api + "/parts/d/" + did + "/w/" + wid + "/e/" + eid + "/partid/"+pid+"/stl?units=meter")
        req.raise_for_status()
        with tempfile.NamedTemporaryFile() as temp:
            temp.write(str(req.text))
            temp.flush()
            your_mesh = mesh.Mesh.from_file(temp.name)
            volume, cog, inertia = your_mesh.get_mass_properties()
            return [cog[0],cog[1]]

    def exportIMG(self, did, wid, eid):
        try:
            self.cache.get('session')
        except KeyError:
            self.__auth()
        
        #viewMatrix="0.612,0.612,0,0,-0.354,0.354,0.707,0,0.707,-0.707,0.707,0"
        #req = self.session.get(self.api + "/partstudios/d/" + did + "/w/" + wid + "/e/" + eid + "/shadedviews?outputHeight=1000&outputWidth=1000&useAntiAliasing=true&edges=show&viewMatrix="+viewMatrix)
        #data = json.loads(req.text)
        #img=(data['images'][0])
        
        req = self.session.get(self.api + "/thumbnails/d/" + did + "/w/" + wid + "/s/300x300")
        req.raise_for_status()
        return req.content

