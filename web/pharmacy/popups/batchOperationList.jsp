<%@ page import="be.openclinic.pharmacy.ServiceStock,
                 be.openclinic.pharmacy.Batch,
                 be.openclinic.pharmacy.BatchOperation,
                 be.openclinic.pharmacy.ProductStockOperation,
                 java.util.Vector,
                 be.mxs.common.util.system.HTMLEntities" %>
<%@ page import="be.openclinic.pharmacy.ProductStock" %>
<%@ page errorPage="/includes/error.jsp" %>
<%@ include file="/includes/validateUser.jsp" %>
<table width=100%>
<tr class="admin">
	<td><%=getTran("web","operation",sWebLanguage)%></td>
	<td><%=getTran("web","date",sWebLanguage)%></td>
	<td><%=getTran("web","thirdpartytype",sWebLanguage)%></td>
	<td><%=getTran("web","thirdpartyname",sWebLanguage)%></td>
	<td><%=getTran("web","beginlevel",sWebLanguage)%></td>
	<td><%=getTran("web","modification",sWebLanguage)%></td>
	<td><%=getTran("web","endlevel",sWebLanguage)%></td>
	<td><%=getTran("web","user",sWebLanguage)%></td>
	<td><%=getTran("web","prescription",sWebLanguage)%></td>
</tr>
<%
String batchUid=checkString(request.getParameter("batchUid"));
String productStockUid=checkString(request.getParameter("productStockUid"));
	Batch batch = Batch.get(batchUid);
	int endLevel = batch.getLevel();
	Vector operations = Batch.getBatchOperations(batchUid,productStockUid);
	for(int n=0;n<operations.size();n++){
		BatchOperation operation = (BatchOperation)operations.elementAt(n);
		int unitsChanged=operation.getQuantity();
		ProductStockOperation productStockOperation = operation.getProductStockOperation();
		String user = "?";
		if(productStockOperation!=null && productStockOperation.getUpdateUser()!=null && User.getFirstUserName(productStockOperation.getUpdateUser())!=null){
			user = User.getFirstUserName(productStockOperation.getUpdateUser()).toUpperCase();
		}
		String prescription=getTran("web","no",sWebLanguage);
		if(productStockOperation!=null && checkString(productStockOperation.getPrescriptionUid()).length()>0){
			prescription=getTran("web","yes",sWebLanguage);;
		}
		String date=ScreenHelper.formatDate(operation.getDate());
		String thirdparty=checkString(operation.getThirdParty());
		if(operation != null && operation.getType()!=null){
			if(operation.getType().equalsIgnoreCase("receipt")){
				//Incoming 
				if(productStockOperation!=null){
					if(productStockOperation.getSourceDestination()!=null && productStockOperation.getSourceDestination().getObjectType()!=null && productStockOperation.getSourceDestination().getObjectType().equalsIgnoreCase("supplier")){
						thirdparty=	productStockOperation.getSourceDestination().getObjectUid();
					}
					else if(productStockOperation.getSourceDestination()!=null && productStockOperation.getSourceDestination().getObjectType()!=null && productStockOperation.getSourceDestination().getObjectType().equalsIgnoreCase("servicestock")){
						thirdparty=	productStockOperation.getSourceDestination().getObjectUid();
						ServiceStock ss = ServiceStock.get(thirdparty);
						if(ss!=null){
							thirdparty=ScreenHelper.checkString(ss.getName());
						}
					}
					else if(productStockOperation.getSourceDestination()!=null && productStockOperation.getSourceDestination().getObjectType()!=null && productStockOperation.getSourceDestination().getObjectType().equalsIgnoreCase("patient")){
						thirdparty=	productStockOperation.getSourceDestination().getObjectUid();
						AdminPerson person=AdminPerson.getAdminPerson(thirdparty);
						if(person!=null){
							thirdparty=person.lastname.toUpperCase()+", "+person.firstname.toUpperCase();
						}
					}
					out.println("<tr><td class='admin2'>&lt;- "+getTran("productstockoperation.medicationreceipt",productStockOperation.getDescription(),sWebLanguage)+"</td>");
					out.println("<td class='admin2'>"+date+"</td>");
					out.println("<td class='admin2'>"+getTran("productstockoperation.sourcedestinationtype",productStockOperation.getSourceDestination().getObjectType(),sWebLanguage)+"</td>");
					out.println("<td class='admin2'>"+thirdparty+"</td>");
					out.println("<td class='admin2'>"+(endLevel-unitsChanged)+"</td>");
					out.println("<td class='admin2'>+"+unitsChanged+"</td>");
					out.println("<td class='admin2'>"+endLevel+"</td>");
					out.println("<td class='admin2'>"+user+"</td>");
					out.println("<td class='admin2'></td>");
					endLevel-=unitsChanged;			
				}
			}
			else {
				//Outgoing 
				if(productStockOperation!=null){
					if (productStockOperation.getSourceDestination()!=null && productStockOperation.getSourceDestination().getObjectType()!=null && productStockOperation.getSourceDestination().getObjectType().equalsIgnoreCase("patient")){
						AdminPerson person=AdminPerson.getAdminPerson(thirdparty);
						if(person!=null){
							thirdparty=person.lastname.toUpperCase()+", "+person.firstname.toUpperCase();
						}
						out.println("<tr><td class='admin2'>-&gt; "+getTran("productstockoperation.medicationdelivery",productStockOperation.getDescription(),sWebLanguage)+"</td>");
					}
					else if(productStockOperation.getSourceDestination()!=null && productStockOperation.getSourceDestination().getObjectType()!=null && productStockOperation.getSourceDestination().getObjectType().equalsIgnoreCase("servicestock")){
						thirdparty=	productStockOperation.getSourceDestination().getObjectUid();
						if(thirdparty!=null && thirdparty.length()>0){
							ServiceStock service = ServiceStock.get(thirdparty);
							if(service!=null){
								thirdparty=service.getName();
							}
						}
						out.println("<tr><td class='admin2'>-&gt; "+getTran("productstockoperation.medicationdelivery",productStockOperation.getDescription(),sWebLanguage)+"</td>");
					}
					out.println("<td class='admin2'>"+date+"</td>");
					out.println("<td class='admin2'>"+getTran("productstockoperation.sourcedestinationtype",productStockOperation.getSourceDestination().getObjectType(),sWebLanguage)+"</td>");
					out.println("<td class='admin2'>"+thirdparty+"</td>");
					out.println("<td class='admin2'>"+(endLevel+unitsChanged)+"</td>");
					out.println("<td class='admin2'>"+(-unitsChanged)+"</td>");
					out.println("<td class='admin2'>"+endLevel+"</td>");
					out.println("<td class='admin2'>"+user+"</td>");
					out.println("<td class='admin2'>"+(productStockOperation.getSourceDestination().getObjectType().equalsIgnoreCase("patient")?prescription:"")+"</td>");
					endLevel+=unitsChanged;			
				}
			}
		}
	}
%>
</table>