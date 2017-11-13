# Start listeners list
import time

checkingPort = ''
# Timeout to start listener (sec.)
startTimeout = 20


class AdminConfig(object):
  pass


for eachCell in AdminConfig.list('Cell').split():
    cellName = AdminConfig.showAttribute(eachCell, 'name')
    for eachNode in AdminConfig.list('Node', eachCell).split():
        nodeName = AdminConfig.showAttribute(eachNode, 'name')
        for eachAppserver in AdminConfig.list('Server', eachNode).split():
            if AdminConfig.showAttribute(eachAppserver, 'serverType') == 'APPLICATION_SERVER':
                serverName = AdminConfig.showAttribute(eachAppserver, 'name')
                try:
                    for eachListenerPort in AdminConfig.list('ListenerPort', eachAppserver).split():
                        portName = AdminConfig.showAttribute(eachListenerPort, 'name')
                        listenerPort = AdminControl.queryNames(
                            'type=ListenerPort,cell=%s,node=%s,process=%s,name=%s,*' % (
                            cellName, nodeName, serverName, portName))
                        loopTimeout = time.time() + startTimeout
                        while (AdminControl.getAttribute(listenerPort, 'started') != 'true'):
                            startState = AdminControl.invoke(listenerPort, 'start')
                            time.sleep(5)
                            checkingPort = listenerPort
                            if time.time() > loopTimeout:
                                break
                        try:
                            if (AdminControl.getAttribute(checkingPort, 'started') == 'true'):
                                portState = 'Up'
                            else:
                                portState = 'Start pending'
                            print('Cell=%s, Node=%s, AppSrv=%s, LP_Name=%s, LP_State=%s' % (
                                cellName, nodeName, serverName, portName, portState))
                            checkingPort = ''
                        except:
                            continue
                except:
                    continue
# End script
