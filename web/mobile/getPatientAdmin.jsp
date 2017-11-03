<%@include file="/mobile/_common/head.jsp"%>

<%-- DEMOGRAPHICS -----------------------------%>
<table class="list" padding="0" cellspacing="1" width="<%=sTABLE_WIDTH%>">
	<tr class="admin"><td colspan="2"><%=getTran("mobile","demographics",activeUser)%></td></tr>
	
	<tr><td width="100" class="admin" nowrap><%=getTran("web.admin","nationality",activeUser)%></td><td><%=getTran("country",activePatient.nativeCountry,activeUser)%></td></tr>
	<tr><td class="admin" nowrap><%=getTran("mobile","idcard",activeUser)%></td><td><%=activePatient.getID("natreg")%></td></tr>
	<tr><td class="admin" nowrap><%=getTran("web","language",activeUser)%></td><td><%=getTran("web.language",activePatient.language,activeUser)%></td></tr>
	<tr><td class="admin" nowrap><%=getTran("web","gender",activeUser)%></td><td><%=getTran("gender",activePatient.gender,activeUser)%></td></tr>
	<tr><td class="admin" nowrap><%=getTran("web","civilstatus",activeUser)%></td><td><%=getTran("civil.status",activePatient.comment2,activeUser)%></td></tr>
	<tr><td class="admin" nowrap><%=getTran("web","province",activeUser)%></td><td><%=activePatient.getActivePrivate().province%></td></tr>
	<tr><td class="admin" nowrap><%=getTran("web","district",activeUser)%></td><td><%=activePatient.getActivePrivate().district%></td></tr>
	<tr><td class="admin" nowrap><%=getTran("web","city",activeUser)%></td><td><%=activePatient.getActivePrivate().city%></td></tr>
	<tr><td class="admin" nowrap><%=getTran("web","telephone",activeUser)%></td><td><%=activePatient.getActivePrivate().telephone%></td></tr>
</table>
<div style="padding-top:5px;"></div>

<%-- ADT --------------------------------------%>
<table class="list" padding="0" cellspacing="1" width="<%=sTABLE_WIDTH%>">
	<tr class="admin"><td colspan="3"><%=getTran("web","adt",activeUser)%></td></tr>
	
	<tr class="gray"><td colspan="3"><%=getTran("web","active_encounter",activeUser)%></td></tr>
	<%
		Encounter activeContact = Encounter.getActiveEncounter(activePatient.personid);	
		if(activeContact!=null){
			// 1 - general 
			out.print("<tr><td class='admin' width='100' nowrap>"+getTran("web.occup","medwan.common.contacttype",activeUser)+"</td><td>"+getTran("encountertype",activeContact.getType(),activeUser)+"</td></tr>");
			out.print("<tr><td class='admin' nowrap>"+getTran("web","begin",activeUser)+"</td><td>"+stdDateFormat.format(activeContact.getBegin())+"</td></tr>");
			out.print("<tr><td class='admin' nowrap>"+getTran("openclinic.chuk","urgency.origin",activeUser)+"</td><td>"+getTran("urgency.origin",activeContact.getOrigin(),activeUser)+"</td></tr>");
			if(activeContact.getManager()!=null && activeContact.getManager().person!=null){
				out.print("<tr><td class='admin' nowrap>"+getTran("web","manager",activeUser)+"</td><td>"+activeContact.getManager().person.getFullName()+"</td></tr>");
			}
			out.print("<tr><td class='admin' nowrap>"+getTran("web","service",activeUser)+"</td><td>"+activeContact.getService().getLabel(activeUser.person.language)+"</td></tr>");

			out.print("</table>");
			out.print("<div style='padding-top:3px;'>");
			
			// 2 - reasons for encounter
            out.print("<table padding='0' cellspacing='0' width='"+sTABLE_WIDTH+"'>"); 
			out.print("<tr class='gray'><td colspan='3'>"+getTran("openclinic.chuk","rfe",activeUser)+"</td></tr>");
			out.print("<tr><td colspan='2' style='padding-left:3px'>"+getReasonsForEncounterAsHtml(activeContact.getUid(),activeUser.person.language)+"</td></tr>");
		}
	%>
</table>
<div style="padding-top:3px;">

   <table class="list" padding="0" cellspacing="1" width="<%=sTABLE_WIDTH%>">
	<tr class="gray"><td colspan="3"><%=getTran("mobile","lastContacts",activeUser)%></td></tr>
	<%
	    // 3 - last contacts
		Encounter lastvisit = Encounter.getInactiveEncounterBefore(activePatient.personid,"visit",new java.util.Date());
		if(lastvisit!=null){
			out.print("<tr>"+
		               "<td class='admin' width='100' nowrap>"+getTran("encountertype","visit",activeUser)+"</td>"+
		               "<td>"+stdDateFormat.format(lastvisit.getBegin())+": "+lastvisit.getService().getLabel(activeUser.person.language)+"</td>"+
					  "</tr>");
		}
		
		Encounter lastadmission = Encounter.getInactiveEncounterBefore(activePatient.personid,"admission",new java.util.Date());
		if(lastadmission!=null){
			out.print("<tr><td class='admin' width='100' nowrap>"+getTran("encountertype","admission",activeUser)+"</td><td width='90%'>"+stdDateFormat.format(lastadmission.getBegin())+": "+lastadmission.getService().getLabel(activeUser.person.language)+"</td></tr>");
		}

		if(lastvisit==null && lastadmission==null){
			out.print("<tr><td colspan='2' style='padding-left:3px;'><i>"+getTran("web","noData",activeUser)+"</i></td></tr>");
		}
	%>
</table>
			
<%-- BUTTONS --%>
<%=alignButtonsStart()%>
    <input type="button" class="button" name="backButton" onclick="showPatientMenu();" value="<%=getTranNoLink("web","back",activeUser)%>">
<%=alignButtonsStop()%>
			
<%@include file="/mobile/_common/footer.jsp"%>