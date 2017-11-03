<%@include file="/includes/helper.jsp"%>
<head>
    <%=sCSSNORMAL%>
    <%=sJSPROTOTYPE%>
    
    <script>
      window.resizeTo(400,200);
      window.moveTo((self.screen.width-document.body.clientWidth)/2,(self.screen.height-document.body.clientHeight)/2);
    </script>
</head>

<body>
<script>  
  var _app = navigator.appName;
  	
  function onErrorHandler(){
    alert("Error");
  }
  	
  function onLoadHandler(){
    document.UareUApplet.SelectFormatISO();
  }

  function onDisconnectedHandler(){
    setTimeout('document.getElementById("readerID").innerHTML="<%=getTranNoLink("web","no.reader","en")%>"');
  }

  function onConnectedHandler(reader){
    document.getElementById('readerID').innerHTML=reader+' <%=getTranNoLink("web","detected","en")%>';
    document.UareUApplet.SelectFormatISO();
  }

  function onCaptureHandler(){
  }

  function onEnrollmentFailureHandler(){
  }

  function onFMDHandler(hexFMD){
  	document.getElementById("fingerprintImage").src='<c:url value="/_img/fingerprintImageSmall.jpg"/>';
	document.getElementById('readerID').innerHTML='<%=getTranNoLink("web","checking.fingerprint","en")%>';

	var url = '<c:url value="/_common/identifyFingerPrint.jsp"/>?ts='+new Date().getTime();
	var parameters= 'fmd='+hexFMD+'&user=true';
	
	new Ajax.Request(url,{
	  method: "POST",
	  postBody: parameters,
	  onSuccess: function(resp){
	    var s=eval('('+resp.responseText+')');
	    if(s.personid!="0"){
	      setTimeout("selectUser('"+s.personid+"','"+s.password+"')",1000);
	    }
	    else{
	      document.getElementById("fingerprintImage").src="<c:url value="/_img/fingerprintImageSmallWrong.jpg"/>";
		  document.getElementById('readerID').innerHTML='<%=getTranNoLink("web","unknown.fingerprint","en")%>';
		  setTimeout("document.getElementById('fingerprintImage').src='<c:url value="/_img/fingerprintImageSmallNoPrint.jpg"/>'",3000);
	    }
	  },
	  onFailure: function(){
        setTimeout("document.getElementById('fingerprintImage').src='<c:url value="/_img/fingerprintImageSmallNoPrint.jpg"/>'",500);
		document.getElementById('readerID').innerHTML='<%=getTranNoLink("web","error.fingerprint","en")%>';
	  }
	});
  }

  function selectUser(userid,password){
    window.opener.location.href='<c:url value="/checkLogin.jsp"/>?ts=<%=ScreenHelper.getTs()%>&login='+userid+'&auto=true&password='+password;
    window.close();
  }
	
  function setFormat(radioObj){
  }

  if(_app=='Netscape' || _app == 'Opera'){
    document.write('<object classid="java:UareUApplet.class"',
     'type="application/x-java-applet"',
     'name="UareUApplet"',
     'width="1"',  //apparently need to have dimension > 0 for foreground window to be associated with jvm process.
     'height="0"', //otherwise, if w&h=0, must use exlusive priority
     'type="application/x-java-applet"',
     'pluginspage="http://java.sun.com/javase/downloads"',
     'archive="<%=request.getRequestURI().replaceAll(request.getServletPath(),"")%>/_common/UareUApplet.jar,<%=request.getRequestURI().replaceAll(request.getServletPath(),"")%>/_common/dpuareu.jar"',
     'onFMDAcquiredScript="onFMDHandler"',
     'onEnrollmentFailureScript="onEnrollmentFailureHandler"',
     'onImageCapturedScript="onCaptureHandler"',
     'onErrorScript="onErrorHandler"',
     'onLoadScript="onLoadHandler"',
     'onDisconnectedScript="onDisconnectedHandler"',
     'onConnectedScript="onConnectedHandler"',
     'bRegistrationMode="false"',
     'bDebug="true"',
     'bExclusivePriority="true"',
     'scriptable="true"',
     'mayscript="true"',
     'separate_jvm="true"> </object>');
  }
  else if(_app=="Microsoft Internet Explorer"){
	 document.write( '<object classid="clsid:8AD9C840-044E-11D1-B3E9-00805F499D93"',
	  'height="1" width="0" name="UareUApplet">',
	  '<param name="type" value="application/x-java-applet;version=1.6" />',
	  '<param name="code" value="UareUApplet"/>',
	  '<param name="scriptable" value="true" />',
	  '<param name="archive" value="<%=request.getRequestURI().replaceAll(request.getServletPath(),"")%>/_common/UareUApplet.jar,<%=request.getRequestURI().replaceAll(request.getServletPath(),"")%>/_common/dpuareu.jar"/>',
	  '<param name="onFMDAcquiredScript" value="onFMDHandler" />',
	  '<param name="onImageCapturedScript" value="onCaptureHandler" />',
	  '<param name="onEnrollmentFailureScript" value="onEnrollmentFailureHandler"/>',
	  '<param name="bDebug" value="true" />',
	  '<param name="bRegistrationMode" value="false" />',
	  '<param name="onErrorScript" value="onErrorHandler" />',
	  '<param name="onLoadScript" value="onLoadHandler" />',
	  '<param name="onDisconnectedScript" value="onDisconnectedHandler" />',
	  '<param name="onConnectedScript" value="onConnectedHandler" />',
	  '<param name="bExclusivePriority" value="false"/>',
	  '<param name="separate_jvm" value="true" />',
	  '</object>');
  }
</script>

<table width='100%'>
	<tr>
		<td>
			<table width='100%'>
				<tr>
					<td><%=("<img src='" + request.getParameter("referringServer") + "/_img/themes/"+(sUserTheme.length()==0?"default":sUserTheme)+"/ajax-loader.gif'/><br><br>"+MedwanQuery.getInstance().getLabel("web","waiting_for_fingerprint","en")+"</br>")%></td>
				</tr>
				<tr>
					<td>
						<form name="frmFingerPrint" method="post" action="http://localhost/openclinic/_common/readFingerPrint.jsp">
						    <label name='readerID' id='readerID'></label>
						</form>
					</td>
				</tr>
			</table>
		</td>
		<td>
			<img width='80px' id='fingerprintImage' name='fingerprintImage' src="<c:url value="/_img/fingerprintImageSmallNoPrint.jpg"/>"/>
		</td>
	</tr>
</table>