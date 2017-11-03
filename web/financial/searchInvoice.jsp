<%@page import="be.openclinic.finance.*,
                java.util.*,
                java.text.DecimalFormat,
                be.openclinic.finance.ExtraInsurarInvoice"%>
<%@page errorPage="/includes/error.jsp"%>
<%@include file="/includes/validateUser.jsp"%>
<%=checkPermission("financial.insuranceinvoice","select",activeUser)%>
<%=sJSSORTTABLE%>

<%
    String sFindDateBegin   = checkString(request.getParameter("FindDateBegin")),
           sFindDateEnd     = checkString(request.getParameter("FindDateEnd")),
           sFindAmountMin   = checkString(request.getParameter("FindAmountMin")),
           sFindAmountMax   = checkString(request.getParameter("FindAmountMax")),
           sFindInvoiceId   = checkString(request.getParameter("FindInvoiceId")),
           sFindInvoiceType = checkString(request.getParameter("FindInvoiceType"));

    /// DEBUG /////////////////////////////////////////////////////////////////////////////////////
    if(Debug.enabled){
        Debug.println("\n********************* financial/searchInvoice.jsp *********************");
        Debug.println("sFindDateBegin   : "+sFindDateBegin);
        Debug.println("sFindDateEnd     : "+sFindDateEnd);
        Debug.println("sFindAmountMin   : "+sFindAmountMin);
        Debug.println("sFindAmountMax   : "+sFindAmountMax);
        Debug.println("sFindInvoiceId   : "+sFindInvoiceId);
        Debug.println("sFindInvoiceType : "+sFindInvoiceType+"\n");
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////

%>
<body onkeydown="if(enterEvent(event,13)){doFind();}">
<form name='FindForm' id="FindForm" method='POST'>
    <%=writeTableHeader("web","searchInvoice",sWebLanguage)%>
    
    <table class="menu" width="100%" cellspacing="1" cellpadding="0">
         <%-- DATES --%>
         <tr>
            <td class="admin" width="<%=sTDAdminWidth%>"><%=getTran("Web","date",sWebLanguage)%></td>
            <td class="admin2" width="70"><%=getTran("Web","Begin",sWebLanguage)%></td>
            <td class="admin2" width="130"><%=writeDateField("FindDateBegin","FindForm",sFindDateBegin,sWebLanguage)%></td>
            <td class="admin2" width="110"><%=getTran("Web","End",sWebLanguage)%></td>
            <td class="admin2"><%=writeDateField("FindDateEnd","FindForm",sFindDateEnd,sWebLanguage)%></td>
        </tr>
        
        <%-- AMOUNT --%>
        <tr>
            <td class="admin"><%=getTran("Web","amount",sWebLanguage)%></td>
            <td class="admin2"><%=getTran("Web","min",sWebLanguage)%></td>
            <td class="admin2"><input type="text" class="text" size="10" name="FindAmountMin" id="FindAmountMin" value="<%=sFindAmountMin%>" onblur="isNumber(this)"> <%=MedwanQuery.getInstance().getConfigParam("currency", "�")%></td>
            <td class="admin2"><%=getTran("Web","max",sWebLanguage)%></td>
            <td class="admin2"><input type="text" class="text" size="10" name="FindAmountMax" id="FindAmountMax" value="<%=sFindAmountMax%>" onblur="isNumber(this)"> <%=MedwanQuery.getInstance().getConfigParam("currency", "�")%></td>
        </tr>
        
        <%-- INVOICE ID --%>
        <tr>
            <td class="admin"><%=getTran("web.finance","invoiceid",sWebLanguage)%></td>
            <td class="admin2" colspan="4"><input type="text" class="text" size="10" name="FindInvoiceId" id="FindInvoiceId" value="<%=sFindInvoiceId%>" onblur="isNumber(this)"></td>
        </tr>
        
        <%-- TYPE --%>
        <tr>
            <td class="admin"><%=getTran("web.finance","invoicetype",sWebLanguage)%></td>
            <td class="admin2" colspan="4">
                <input type="radio" onDblClick="uncheckRadio(this);" id="FindType1" name="FindInvoiceType" value="patient" <%if(sFindInvoiceType.equalsIgnoreCase("patient")){out.print("checked");}%>><%=getLabel("web","patient",sWebLanguage,"FindType1")%>
                <input type="radio" onDblClick="uncheckRadio(this);" id="FindType2" name="FindInvoiceType" value="insurar" <%if(sFindInvoiceType.equalsIgnoreCase("insurar") || sFindInvoiceType.equalsIgnoreCase("")){out.print("checked");}%>><%=getLabel("web","insurar",sWebLanguage,"FindType2")%>
                <input type="radio" onDblClick="uncheckRadio(this);" id="FindType3" name="FindInvoiceType" value="extrainsurar" <%if(sFindInvoiceType.equalsIgnoreCase("extrainsurar")){out.print("checked");}%>><%=getLabel("web","extrainsurar",sWebLanguage,"FindType3")%>
                <input type="radio" onDblClick="uncheckRadio(this);" id="FindType4" name="FindInvoiceType" value="extrainsurar2" <%if(sFindInvoiceType.equalsIgnoreCase("extrainsurar2")){out.print("checked");}%>><%=getLabel("web","complementarycoverage2",sWebLanguage,"FindType4")%>
            </td>
        </tr>
        
        <%-- BUTTONS --%>
        <tr>
            <td class="admin">&nbsp;</td>
            <td class="admin2" colspan="4">
                <input type="button" class="button" name="ButtonSearch" value="<%=getTranNoLink("Web","search",sWebLanguage)%>" onclick="doFind();">&nbsp;
                <input type="button" class="button" name="ButtonClear" value="<%=getTranNoLink("Web","Clear",sWebLanguage)%>" onclick="clearFields()">&nbsp;
            </td>
        </tr>
    </table>
</form>

<%
    if((sFindDateBegin.length() > 0) || (sFindDateEnd.length() > 0) || (sFindAmountMin.length() > 0) ||
    	(sFindAmountMax.length() > 0) || (sFindInvoiceId.length() > 0)){
        Vector vPatients = new Vector();
        Vector vInsurars = new Vector();
        Vector vExtraInsurars = new Vector();
        Vector vExtraInsurars2 = new Vector();

        if(sFindInvoiceType.equalsIgnoreCase("patient") || sFindInvoiceType.equals("")){
            vPatients = PatientInvoice.searchInvoices(sFindDateBegin,sFindDateEnd,sFindInvoiceId,sFindAmountMin,sFindAmountMax);
        }
        else if(sFindInvoiceType.equalsIgnoreCase("insurar")){
            vInsurars = InsurarInvoice.searchInvoices(sFindDateBegin,sFindDateEnd,sFindInvoiceId,sFindAmountMin,sFindAmountMax);
        }
        else if(sFindInvoiceType.equalsIgnoreCase("extrainsurar")){
            vExtraInsurars = ExtraInsurarInvoice.searchInvoices(sFindDateBegin,sFindDateEnd,sFindInvoiceId,sFindAmountMin,sFindAmountMax);
	    }
        else if(sFindInvoiceType.equalsIgnoreCase("extrainsurar2")){
	        vExtraInsurars2 = ExtraInsurarInvoice2.searchInvoices(sFindDateBegin,sFindDateEnd,sFindInvoiceId,sFindAmountMin,sFindAmountMax);
	    }
        
        Hashtable hInvoices = new Hashtable();
        PatientInvoice patientInvoice;
        for(int i=0; i<vPatients.size(); i++){
            patientInvoice = (PatientInvoice)vPatients.elementAt(i);

            if(patientInvoice!=null){
                hInvoices.put(new Integer(patientInvoice.getInvoiceUid()),patientInvoice);
            }
        }

        InsurarInvoice insurarInvoice;
        for(int i=0; i<vInsurars.size(); i++){
            insurarInvoice = (InsurarInvoice)vInsurars.elementAt(i);

            if(insurarInvoice!=null){
                hInvoices.put(new Integer(insurarInvoice.getInvoiceUid()),insurarInvoice);
            }
        }
        
        ExtraInsurarInvoice extrainsurarInvoice;
        for(int i=0; i<vExtraInsurars.size(); i++){
            extrainsurarInvoice = (ExtraInsurarInvoice)vExtraInsurars.elementAt(i);

            if(extrainsurarInvoice!=null){
                hInvoices.put(new Integer(extrainsurarInvoice.getInvoiceUid()),extrainsurarInvoice);
            }
        }
        
        ExtraInsurarInvoice2 extrainsurarInvoice2;
        for(int i=0; i<vExtraInsurars2.size(); i++){
            extrainsurarInvoice2 = (ExtraInsurarInvoice2)vExtraInsurars2.elementAt(i);

            if(extrainsurarInvoice2!=null){
                hInvoices.put(new Integer(extrainsurarInvoice2.getInvoiceUid()),extrainsurarInvoice2);
            }
        }
        
        %>
        <table width="100%" cellspacing="0" cellpadding="0" class="sortable" id="searchresults">
            <%-- header --%>
            <tr class="admin">
                <td width="90"><%=getTran("web.finance","invoiceid",sWebLanguage)%></td>
                <td width="110"><SORTTYPE:DATE><%=getTran("web","date",sWebLanguage)%></SORTTYPE:DATE></td>
                <td width="200"><%=getTran("web","destination",sWebLanguage)%></td>
                <td width="150"><%=getTran("web.finance","invoicetype",sWebLanguage)%></td>
                <td width="90"><%=getTran("Web","amount",sWebLanguage)+" "+MedwanQuery.getInstance().getConfigParam("currency","�")%></td>
                <td width="80"><%=getTran("Web.finance","payed",sWebLanguage)%></td>
                <td width="*"><%=getTran("web.finance","patientinvoice.status",sWebLanguage)%></td>
            </tr>
            
            <tbody class="hand">
            <%
                String sClass = "1", sRowDate = "", sRowDestination = "", sRowType = "",
                       sRowAmount = "", sRowPayed = "", sRowStatus = "";
                Integer iInvoiceId;
                Vector v = new Vector(hInvoices.keySet());
                Collections.sort(v);
                Iterator it = v.iterator();

                while(it.hasNext()){
                    iInvoiceId = (Integer)it.next();
                    Object object = hInvoices.get(iInvoiceId);
                    sRowPayed = "";

                    try{
	                    if(object.getClass().getName().equals("be.openclinic.finance.PatientInvoice")){
	                        patientInvoice = (PatientInvoice) object;
	                        sRowDate = ScreenHelper.getSQLDate(patientInvoice.getDate());
	                        sRowDestination = patientInvoice.getPatient().lastname+", "+patientInvoice.getPatient().firstname;
	                        sRowAmount = new DecimalFormat("#0.00").format(patientInvoice.getBalance());
	                        sRowStatus = patientInvoice.getStatus();
	                        sRowType = getTran("web","patient",sWebLanguage);
	                    }
	                    else if(object.getClass().getName().equals("be.openclinic.finance.InsurarInvoice")){
	                        insurarInvoice = (InsurarInvoice) object;
	                        sRowDate = ScreenHelper.getSQLDate(insurarInvoice.getDate());
	                        sRowDestination = insurarInvoice.getInsurar().getName();
	                        sRowAmount = new DecimalFormat("#0.00").format(insurarInvoice.getBalance());
	                        sRowStatus = insurarInvoice.getStatus();
	                        sRowType = getTran("web","insurar",sWebLanguage);
	                    }
	                    else if(object.getClass().getName().equals("be.openclinic.finance.ExtraInsurarInvoice")){
	                        extrainsurarInvoice = (ExtraInsurarInvoice) object;
	                        sRowDate = ScreenHelper.getSQLDate(extrainsurarInvoice.getDate());
	                        sRowDestination = extrainsurarInvoice.getInsurar().getName();
	                        sRowAmount = new DecimalFormat("#0.00").format(extrainsurarInvoice.getBalance());
	                        sRowStatus = extrainsurarInvoice.getStatus();
	                        sRowType = getTran("web","extrainsurar",sWebLanguage);
	                    }
	                    else if(object.getClass().getName().equals("be.openclinic.finance.ExtraInsurarInvoice2")){
	                        extrainsurarInvoice2 = (ExtraInsurarInvoice2) object;
	                        sRowDate = ScreenHelper.getSQLDate(extrainsurarInvoice2.getDate());
	                        sRowDestination = extrainsurarInvoice2.getInsurar().getName();
	                        sRowAmount = new DecimalFormat("#0.00").format(extrainsurarInvoice2.getBalance());
	                        sRowStatus = extrainsurarInvoice2.getStatus();
	                        sRowType = getTran("web","complementarycoverage2",sWebLanguage);
	                    }
	
	                    if(sRowStatus.equalsIgnoreCase("closed")||sRowStatus.equalsIgnoreCase("canceled")){
	                        sRowPayed = "Ok";
	                    }
	
	                    // alternate row-styles
	                    if(sClass.equals("1")) sClass = "";
	                    else                   sClass = "1";
                    }
                    catch(Exception e2){
                        e2.printStackTrace();
                    }
                    
                    %>
                    <tr class="list<%=sClass%>" onclick="openInvoice('<%=iInvoiceId.toString()%>','<%=sRowType%>')">
                        <td><%=iInvoiceId.toString()%></td>
                        <td><%=sRowDate%></td>
                        <td><%=sRowDestination%></td>
                        <td><%=sRowType%></td>
                        <td><%=sRowAmount%></td>
                        <td><%=sRowPayed%></td>
                        <td><%=getTran("finance.patientinvoice.status",sRowStatus,sWebLanguage)%></td>
                    </tr>
                    <%
                 }
            %>
            </tbody>
        </table>
        <%
        
        if(hInvoices.size() > 0){
            %><%=hInvoices.size()%> <%=getTran("web","recordsFound",sWebLanguage)%><% 
        }
        else{
        	%><%=getTran("web","noRecordsFound",sWebLanguage)%><%
        }
    }
%>
<script>
  <%-- DO FIND --%>
  function doFind(){
    if((document.getElementById("FindDateBegin").value.length>0)
      ||(document.getElementById("FindDateEnd").value.length>0)
      ||(document.getElementById("FindAmountMin").value.length>0)
      ||(document.getElementById("FindAmountMax").value.length>0)
      ||(document.getElementById("FindInvoiceId").value.length>0)
    ){
      FindForm.submit();
    }
    else{
                window.showModalDialog?alertDialog("web.manage","dataMissing"):alertDialogDirectText('<%=getTran("web.manage","dataMissing",sWebLanguage)%>');
    }
  }

  <%-- CLEAR FIELDS --%>
  function clearFields(){
    document.getElementById("FindDateBegin").value = "";
    document.getElementById("FindDateEnd").value = "";
    document.getElementById("FindAmountMin").value = "";
    document.getElementById("FindAmountMax").value = "";
    document.getElementById("FindInvoiceId").value = "";
    
    document.getElementById("FindType1").checked = false;
    document.getElementById("FindType2").checked = false;
    document.getElementById("FindType3").checked = false;
    document.getElementById("FindType4").checked = false;
  }

  <%-- OPEN INVOICE --%>
  function openInvoice(sInvoiceId,sType){
    if(sType=="<%=getTranNoLink("web","patient",sWebLanguage)%>"){
      openPopup("/financial/patientInvoiceEdit.jsp&ts=<%=getTs()%>&PopupWidth=610&PopupHeight=660&FindPatientInvoiceUID="+sInvoiceId);
    }
    else if(sType=="<%=getTranNoLink("web","insurar",sWebLanguage)%>"){
      openPopup("/financial/insuranceInvoiceEdit.jsp&ts=<%=getTs()%>&PopupWidth=600&PopupHeight=690&FindInsurarInvoiceUID="+sInvoiceId);
    }
    else if(sType=="<%=getTranNoLink("web","extrainsurar",sWebLanguage)%>"){
      openPopup("/financial/extraInsuranceInvoiceEdit.jsp&ts=<%=getTs()%>&PopupWidth=600&PopupHeight=690&FindInsurarInvoiceUID="+sInvoiceId);
    }
    else if(sType=="<%=getTranNoLink("web","complementarycoverage2",sWebLanguage)%>"){
      openPopup("/financial/extraInsuranceInvoiceEdit2.jsp&ts=<%=getTs()%>&PopupWidth=600&PopupHeight=690&FindInsurarInvoiceUID="+sInvoiceId);
    }
  }
</script>