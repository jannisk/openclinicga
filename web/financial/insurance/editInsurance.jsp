<%@page import="be.openclinic.finance.*,
                be.mxs.common.util.system.*"%>
<%@include file="/includes/validateUser.jsp"%>

<script>
  function searchInsuranceCategory(){
	openPopup("/_common/search/searchInsuranceCategory.jsp&ts=<%=getTs()%>&VarCode=EditInsuranceCategoryLetter"+
			  "&VarText=EditInsuranceInsurarName&VarCat=EditInsuranceCategory&VarCompUID=EditInsurarUID"+
			  "&VarTyp=EditInsuranceType&VarTypName=EditInsuranceTypeName&"+
			  "VarFunction=checkInsuranceAuthorization()&Active=1");
  }
	
  function doBack(){
    window.location.href="<c:url value='/main.do'/>?Page=curative/index.jsp&ts=<%=getTs()%>";
  }

  function doSearchBack(){
    window.location.href="<c:url value='/main.do'/>?Page=curative/index.jsp&ts=<%=getTs()%>";
  }

  <%-- DO SAVE --%>
  function doSave(){
    if("<%=MedwanQuery.getInstance().getConfigString("InsuranceAgentAuthorizationNeededFor","$$").replaceAll("\\*","")%>"==document.getElementById('EditInsurarUID').value && document.getElementById('EditInsuranceNr').value==''){
      alertDialog("web","insurancenr.mandatory");
    }
    else if("<%=MedwanQuery.getInstance().getConfigString("InsuranceAgentAuthorizationNeededFor","$$").replaceAll("\\*","")%>"==document.getElementById('EditInsurarUID').value && document.getElementById('EditInsuranceStatus').value==''){
      alertDialog("web","insurancestatus.mandatory");
    }
   	else if(EditInsuranceForm.EditInsuranceStart && EditInsuranceForm.EditInsuranceStart.value.length<8){
   	  alertDialog("web","insurancedatestart.mandatory");
   	}
  	else{
      EditInsuranceForm.EditSaveButton.disabled = true;
      EditInsuranceForm.Action.value = "SAVE";
      EditInsuranceForm.submit();
    }
  }
</script>

<%=checkPermission("financial.insurance","select",activeUser)%>

<%
    String sAction = checkString(request.getParameter("Action"));

	String sEditInsuranceUID = checkString(request.getParameter("EditInsuranceUID"));
    String sEditInsurarUID = checkString(request.getParameter("EditInsurarUID"));
	String sEditExtraInsurarUID = checkString(request.getParameter("EditExtraInsurarUID"));
	String sEditExtraInsurarUID2 = checkString(request.getParameter("EditExtraInsurarUID2"));
    String sEditInsuranceNr = checkString(request.getParameter("EditInsuranceNr"));
    String sEditInsuranceType = checkString(request.getParameter("EditInsuranceType"));
    String sEditInsuranceMember = checkString(request.getParameter("EditInsuranceMember"));
    String sEditInsuranceMemberImmat = checkString(request.getParameter("EditInsuranceMemberImmat"));
    String sEditInsuranceMemberEmployer = checkString(request.getParameter("EditInsuranceMemberEmployer"));
    String sEditInsuranceStatus = checkString(request.getParameter("EditInsuranceStatus"));
    String sEditAuthorization = checkString(request.getParameter("EditAuthorization"));
    String sEditInsuranceStart = checkString(request.getParameter("EditInsuranceStart"));
    if(sEditInsuranceStart.length()==0){
        sEditInsuranceStart = ScreenHelper.stdDateFormat.format(new java.util.Date());
    }
    String sEditInsuranceStop = checkString(request.getParameter("EditInsuranceStop"));
    String sEditInsuranceCategoryLetter = checkString(request.getParameter("EditInsuranceCategoryLetter"));
    String sEditInsuranceCategory = "";
    String sEditInsuranceInsurarName = "";
    String sEditInsuranceComment = checkString(request.getParameter("EditInsuranceComment"));
    String sEditInsuranceDefault = checkString(request.getParameter("EditInsuranceDefault"));
	if(sEditInsuranceDefault.length()==0){
		sEditInsuranceDefault = "0";
	}
	
	boolean bCanSave = true;
	
	//***** SAVE *****
    if(sAction.equals("SAVE")){
        if(sEditInsurarUID.length()!=0){
        	Insurar insurar = Insurar.get(sEditInsurarUID);
        	if(insurar!=null && insurar.getRequireAffiliateID()==1 && sEditInsuranceNr.length()==0){
        		out.print("<script>alertDialog('web','requireaffiliateid');</script>");
        		bCanSave = false;
        	}
        }
        
        if(bCanSave){
	        if(sEditInsuranceCategoryLetter.length()==0){
	            sEditInsurarUID = "";
	        }
	        
	        Insurance insurance = new Insurance();
	        if(sEditInsuranceUID.length() > 0){
	            insurance = Insurance.get(sEditInsuranceUID);
	        }
	        else{
	            insurance.setCreateDateTime(getSQLTime());
	        }
	
	        if(sEditInsuranceStart.length() > 0){
	            insurance.setStart(new Timestamp(ScreenHelper.getSQLDate(sEditInsuranceStart).getTime()));
	        }
	        
	        if(sEditInsuranceStop.length() > 0) {
	            insurance.setStop(new Timestamp(ScreenHelper.getSQLDate(sEditInsuranceStop).getTime()));
	        }
	        
	        insurance.setInsuranceNr(sEditInsuranceNr);
	        insurance.setType(sEditInsuranceType);
	        insurance.setMember(sEditInsuranceMember);
	        insurance.setMemberImmat(sEditInsuranceMemberImmat);
	        insurance.setMemberEmployer(sEditInsuranceMemberEmployer);
	        insurance.setStatus(sEditInsuranceStatus);
	        insurance.setInsuranceCategoryLetter(sEditInsuranceCategoryLetter);
	        insurance.setComment(new StringBuffer(sEditInsuranceComment));
	        insurance.setUpdateDateTime(getSQLTime());
	        insurance.setUpdateUser(activeUser.userid);
	        insurance.setPatientUID(activePatient.personid);
	        insurance.setInsurarUid(sEditInsurarUID);
	        insurance.setExtraInsurarUid(sEditExtraInsurarUID);
	        insurance.setExtraInsurarUid2(sEditExtraInsurarUID2);
	        insurance.setDefaultInsurance(Integer.parseInt(sEditInsuranceDefault));
	        insurance.store();
	        
	        if(insurance.getDefaultInsurance()==1){
	        	// Cancel defaults for other insurances of this patient
	        	Vector insurances = Insurance.selectInsurances(activePatient.personid,"");
	        	for(int n=0; n<insurances.size(); n++){
	        		Insurance ins = (Insurance)insurances.elementAt(n);
	        		if(!ins.getUid().equals(insurance.getUid())){
	        			ins.setDefaultInsurance(0);
	        			ins.store();
	        		}
	        	}
	        			
	        }
	        if(sEditAuthorization.length() > 0){
	        	Pointer.storePointer("AUTH."+sEditInsurarUID+"."+activePatient.personid+"."+new SimpleDateFormat("yyyyMM").format(new java.util.Date()), new SimpleDateFormat("yyyyMMddHHmmss").format(new java.util.Date(new java.util.Date().getTime()+24*3600*1000))+";"+activeUser.userid);
	        }
	        
	        out.print("<script>doSearchBack();</script>");
        }
        out.flush();
    }

    if(sEditInsuranceUID.length() > 0 && bCanSave){
    	Insurance insurance = Insurance.get(sEditInsuranceUID);

        sEditInsuranceNr = insurance.getInsuranceNr();
        sEditInsuranceType = insurance.getType();
        sEditInsuranceMember = insurance.getMember();
        sEditInsuranceMemberImmat = insurance.getMemberImmat();
        sEditInsuranceMemberEmployer = insurance.getMemberEmployer();
        sEditInsuranceStatus = insurance.getStatus();
        sEditInsuranceCategoryLetter = insurance.getInsuranceCategoryLetter();
        sEditInsurarUID = insurance.getInsurarUid();
        sEditExtraInsurarUID = insurance.getExtraInsurarUid();
        sEditExtraInsurarUID2 = insurance.getExtraInsurarUid2();
        
        if(insurance.getStart() != null){
            sEditInsuranceStart = ScreenHelper.stdDateFormat.format(insurance.getStart());
        } 
        else{
            sEditInsuranceStart = "";
        }
        
        if(insurance.getStop() != null){
            sEditInsuranceStop = ScreenHelper.stdDateFormat.format(insurance.getStop());
        }
        else{
            sEditInsuranceStop = "";
        }
        
        sEditInsuranceComment = insurance.getComment().toString();
        
        InsuranceCategory insuranceCategory = InsuranceCategory.get(sEditInsurarUID,sEditInsuranceCategoryLetter);
        if(insuranceCategory.getLabel().length() > 0){
            sEditInsuranceInsurarName = insuranceCategory.getInsurar().getName();
            sEditInsuranceCategory = insuranceCategory.getCategory()+": "+insuranceCategory.getLabel();
        }
        sEditInsuranceDefault = insurance.getDefaultInsurance()+"";
    }
    else if(sEditInsurarUID.length()>0 && sEditInsuranceCategoryLetter.length() > 0){
        InsuranceCategory insuranceCategory = InsuranceCategory.get(sEditInsurarUID,sEditInsuranceCategoryLetter);
        if(insuranceCategory.getLabel().length() > 0){
            sEditInsuranceInsurarName = insuranceCategory.getInsurar().getName();
            sEditInsuranceCategory = insuranceCategory.getCategory()+": "+insuranceCategory.getLabel();
        }
    }        
%>
<form name="EditInsuranceForm" id="EditInsuranceForm" method="POST" action="<c:url value='/main.do'/>?Page=financial/insurance/editInsurance.jsp&ts=<%=getTs()%>">
    <input type="hidden" name="EditInsuranceUID" value="<%=sEditInsuranceUID%>"/>
    
    <%=writeTableHeader("insurance","manageInsurance",sWebLanguage," doBack();")%>
    <table class='list' border='0' width='100%' cellspacing='1'>
        <%-- insurancenr --%>
        <tr>
            <td class="admin" width="<%=sTDAdminWidth%>"><%=getTran("insurance","insurancenr",sWebLanguage)%></td>
            <td class="admin2">
                <input class="text" type="text" name="EditInsuranceNr" id="EditInsuranceNr" value="<%=sEditInsuranceNr%>" size="<%=sTextWidth%>"/>
            </td>
        </tr>
        
        <%-- status --%>
        <tr>
            <td class="admin" width="<%=sTDAdminWidth%>"><%=getTran("insurance","status",sWebLanguage)%></td>
            <td class="admin2">
                <select class="text" name="EditInsuranceStatus" id="EditInsuranceStatus" onchange="setStatus();">
                    <option value=""></option>
                    <%=ScreenHelper.writeSelectUnsorted("insurance.status",sEditInsuranceStatus,sWebLanguage)%>
                </select>
            </td>
        </tr>
        
        <%-- member --%>
        <tr>
            <td class="admin"><%=getTran("insurance","member",sWebLanguage)%></td>
            <td class="admin2">
                <input class="text" type="text" name="EditInsuranceMember" id="EditInsuranceMember" value="<%=sEditInsuranceMember%>" size="<%=sTextWidth%>"/>
            </td>
        </tr>
<%
	if(MedwanQuery.getInstance().getConfigInt("MFPextendedInformation",0)==1||MedwanQuery.getInstance().getConfigString("edition").equalsIgnoreCase("openpharmacy")||MedwanQuery.getInstance().getConfigString("edition").equalsIgnoreCase("openinsurance")){
%>
        <%-- immat --%>
        <tr>
            <td class="admin" width="<%=sTDAdminWidth%>"><%=getTran("insurance","memberimmat",sWebLanguage)%></td>
            <td class="admin2">
                <input class="text" type="text" name="EditInsuranceMemberImmat" id="EditInsuranceMemberImmat" value="<%=sEditInsuranceMemberImmat%>" size="<%=sTextWidth%>"/>
            </td>
        </tr>
        <%-- employer --%>
        <tr>
            <td class="admin"><%=getTran("insurance","memberemployer",sWebLanguage)%></td>
            <td class="admin2">
                <input class="text" type="text" name="EditInsuranceMemberEmployer" value="<%=sEditInsuranceMemberEmployer%>" size="<%=sTextWidth%>"/>
            </td>
        </tr>
 <%
	}
 %>
        <%-- company --%>
        <tr>
            <td class="admin"><%=getTran("web","company",sWebLanguage)%></td>
            <td class="admin2">
                <input type="hidden" name="EditInsurarUID" id="EditInsurarUID" value="<%=sEditInsurarUID%>"/>
                <input class="text" type="text" readonly name="EditInsuranceInsurarName" value="<%=sEditInsuranceInsurarName%>" size="<%=sTextWidth%>"/>
              
                <img src="<c:url value="/_img/icons/icon_search.gif"/>" class="link" alt="<%=getTranNoLink("Web","select",sWebLanguage)%>" onclick="searchInsuranceCategory();">
                <img src="<c:url value="/_img/icons/icon_delete.gif"/>" class="link" alt="<%=getTranNoLink("Web","clear",sWebLanguage)%>" onclick="EditInsuranceForm.EditInsuranceInsurarName.value='';EditInsuranceForm.EditInsuranceCategory.value='';EditInsuranceForm.EditInsuranceCategoryLetter.value='';checkInsuranceAuthorization()">
            </td>
        </tr>
        <%-- category --%>
        <tr>
            <td class="admin"><%=getTran("web","category",sWebLanguage)%></td>
            <td class="admin2">
                <input type="hidden" name="EditInsuranceCategoryLetter" value="<%=sEditInsuranceCategoryLetter%>"/>
                <input class="text" type="text" readonly name="EditInsuranceCategory" value="<%=sEditInsuranceCategory%>" size="<%=sTextWidth%>"/>
            </td>
        </tr>
        <%-- type --%>
        <tr>
            <td class="admin"><%=getTran("web","tariff",sWebLanguage)%></td>
            <td class="admin2">
                <input type="hidden" name="EditInsuranceType" value="<%=sEditInsuranceType%>"/>
                <input class="text" type="text" readonly name="EditInsuranceTypeName" value="<%=sEditInsuranceType.length()>0?getTran("insurance.types",sEditInsuranceType,sWebLanguage):""%>" size="<%=sTextWidth%>" readonly/>
            </td>
        </tr>
        <%-- complementary coverage --%>
        <tr>
            <td class="admin"><%=getTran("web","complementarycoverage",sWebLanguage)%></td>
            <td class="admin2">
                <select class="text" name="EditExtraInsurarUID" id="EditExtraInsurarUID">
                    <option value=""></option>
                    <%=ScreenHelper.writeSelect("patientsharecoverageinsurance",sEditExtraInsurarUID,sWebLanguage)%>
                </select>
            </td>
        </tr>
        <%
        	if(MedwanQuery.getInstance().getConfigInt("enableComplementaryInsurance2",0)==1){
        %>
        <tr>
            <td class="admin"><%=getTran("web","complementarycoverage2",sWebLanguage)%></td>
            <td class="admin2">
                <select class="text" name="EditExtraInsurarUID2" id="EditExtraInsurarUID2">
                    <option value=""></option>
                    <%=ScreenHelper.writeSelect("patientsharecoverageinsurance2",sEditExtraInsurarUID2,sWebLanguage)%>
                </select>
            </td>
        </tr>
		<%
        	}
		%>        
        <%-- start --%>
        <tr>
            <td class="admin"><%=getTran("web","default.insurance",sWebLanguage)%></td>
            <td class="admin2">
				<input type='checkbox' name='EditInsuranceDefault' id='EditInsuranceDefault' value='1' <%=sEditInsuranceDefault.equalsIgnoreCase("1")?"checked":"" %>/>
            </td>
        </tr>
        <%-- start --%>
        <tr>
            <td class="admin"><%=getTran("web","start",sWebLanguage)%></td>
            <td class="admin2">
                <%
                	if(sEditInsuranceUID.length()==0 || activeUser.getAccessRight("financial.modifyinsurancebegin.select")){
                		out.print(writeDateField("EditInsuranceStart","EditInsuranceForm",sEditInsuranceStart,sWebLanguage));
                	}
                	else {
                		out.print(sEditInsuranceStart+"<input type='hidden' name='EditInsuranceStart' id='EditInsuranceStart' value='"+sEditInsuranceStart+"'/>");
                	}
                %>
            </td>
        </tr>
        <%-- stop --%>
        <tr>
            <td class="admin"><%=getTran("web","stop",sWebLanguage)%></td>
            <td class="admin2">
                <%
                	if(sEditInsuranceUID.length()==0 || activeUser.getAccessRight("financial.modifyinsuranceend.select")){
                		out.println(writeDateField("EditInsuranceStop","EditInsuranceForm",sEditInsuranceStop,sWebLanguage));
                	}
                	else{
                		out.print(sEditInsuranceStop);
                	}
                %>
            </td>
        </tr>
        <%-- comment --%>
        <tr>
            <td class="admin"><%=getTran("web","comment",sWebLanguage)%></td>
            <td class="admin2">
                <%=writeTextarea("EditInsuranceComment","69","4","",sEditInsuranceComment)%>
            </td>
        </tr>
        
        <tr id='authorization'></tr>
        
        <%=ScreenHelper.setFormButtonsStart()%>
	        <%
	        	if((sEditInsuranceUID.length()==0 && activeUser.getAccessRight("financial.insurance.add")) || activeUser.getAccessRight("financial.insurance.edit")){
	                %><input class="button" type="button" name="EditSaveButton" value='<%=getTranNoLink("Web","save",sWebLanguage)%>' onclick="doSave();">&nbsp;<%
	        	}
	        %>

            <input class="button" type="button" name="Backbutton" value='<%=getTranNoLink("Web","Back",sWebLanguage)%>' onclick="doSearchBack();">
        <%=ScreenHelper.setFormButtonsStop()%>
    </table>
    
    <input type="hidden" name="Action" value="">
</form>

<script>
  <%-- SET STATUS --%>
  function setStatus(){
  	if(document.getElementById("EditInsuranceStatus").value=="affiliate"){
       document.getElementById("EditInsuranceMember").value="<%=activePatient.firstname+" "+activePatient.lastname.toUpperCase()%>";
      if(document.getElementById("EditInsuranceMemberImmat")!=null){
        document.getElementById("EditInsuranceMemberImmat").value="<%=activePatient.getID(MedwanQuery.getInstance().getConfigString("EditInsuranceMemberImmatField","immatnew"))%>";
      }
  	}
  }

  <%-- CHECK INSURANCE AUTHORISATION --%>
  function checkInsuranceAuthorization(){
    var params = "insuraruid="+EditInsuranceForm.EditInsurarUID.value+
                 "&personid=<%=activePatient.personid%>"+
                 "&language=<%=sWebLanguage%>"+
                 "&userid=<%=activeUser.userid%>";
    var url= '<c:url value="/financial/checkInsuranceAuthorization.jsp"/>?ts='+new Date();
    new Ajax.Request(url,{
	  method: "POST",
      parameters: params,
      onSuccess: function(resp){
        $('authorization').innerHTML = resp.responseText;
      },
	  onFailure: function(){
	    alert('error');
      }
    });
  }

  checkInsuranceAuthorization();
</script>