require_relative 'xmlrpctest'

# this class enable to use images namespaces operation via xmlrpc-calls
class XMLRPCImageTest < XMLRPCBaseTest
  def deleteImage(imageid)
    @connection.call("image.delete", @sid, imageid)
  end

  def scheduleImageBuild(profile_label, version_build, build_hostid, date)
    @connection.call("image.scheduleImageBuild", @sid, profile_label, version_build, build_hostid, date)
  end

  # list installed packges on the given image
  def listPackages(imageid)
    @connection.call("image.listPackages", @sid, imageid)
  end

  def listImages
    @connection.call("image.listImages", @sid)
  end

  # store methods
  def createStore(label, uri, type, params = {})
    @connection.call("image.store.create", @sid, label, uri, type, params)
  end

  def deleteStore(label)
    @connection.call("image.store.delete", @sid, label)
  end

  def listImageStoreTypes
    @connection.call("image.store.listImageStoreTypes", @sid)
  end

  def listImageStores
    @connection.call("image.store.listImageStores", @sid)
  end
  
end
