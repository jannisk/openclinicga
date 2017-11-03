<%@page import="be.mxs.common.util.system.*,be.openclinic.medical.RequestedLabAnalysis,
                java.util.*,
                be.openclinic.medical.LabRequest,
                be.openclinic.medical.LabAnalysis,
                java.text.DecimalFormat"%>
<%@include file="/includes/validateUser.jsp"%>
<%=checkPermission("system.management","select",activeUser)%>

<%!
    public class LabRow {
        int type;
        String tag;

        public LabRow(int type, String tag){
            this.type = type;
            this.tag = tag;
        }
    }
%>

<head><%=sCSSNORMAL%></head>
<%
    SortedMap requestList = new TreeMap();
    Enumeration parameters = request.getParameterNames();
    while(parameters.hasMoreElements()){
        String name = (String) parameters.nextElement();
        String[] items = name.split("\\.");
        
        if(items[0].equalsIgnoreCase("show")){
            LabRequest labRequest = new LabRequest(Integer.parseInt(items[1]),Integer.parseInt(items[2]));
            if(labRequest.getRequestdate()!=null){
                requestList.put(new SimpleDateFormat("yyyyMMddHHmmss").format(labRequest.getRequestdate())+"."+items[1]+"."+items[2],labRequest);
            }
        }
    }

    SortedMap groups = new TreeMap();
    Iterator iterator = requestList.keySet().iterator();
    while(iterator.hasNext()){
        LabRequest labRequest = (LabRequest)requestList.get(iterator.next());
        
        Enumeration enumeration = labRequest.getAnalyses().elements();
        while(enumeration.hasMoreElements()){
            RequestedLabAnalysis requestedLabAnalysis = (RequestedLabAnalysis)enumeration.nextElement();
            if(groups.get(MedwanQuery.getInstance().getLabel("labanalysis.group",requestedLabAnalysis.getLabgroup(),sWebLanguage))==null){
                groups.put(MedwanQuery.getInstance().getLabel("labanalysis.group",requestedLabAnalysis.getLabgroup(),sWebLanguage),new Hashtable());
            }
            ((Hashtable)groups.get(MedwanQuery.getInstance().getLabel("labanalysis.group",requestedLabAnalysis.getLabgroup(),sWebLanguage))).put(requestedLabAnalysis.getAnalysisCode(),"1");
        }
    }

%>
<%=writeTableHeader("Web","patientLaboResults",sWebLanguage," doBack();")%>
<table class="list" width="100%" cellpadding="0" cellspacing="1">
    <tr>
        <td class="admin2"><%=getTran("web","analysis",sWebLanguage)%></td>
	    <%
	        LabRequest labRequest;
	        Iterator requestsIterator = requestList.keySet().iterator();
	        while(requestsIterator.hasNext()){
	            labRequest = (LabRequest)requestList.get(requestsIterator.next());
	            out.print("<td>"+ScreenHelper.formatDate(labRequest.getRequestdate(),ScreenHelper.fullDateFormat)+"<br/>"+labRequest.getTransactionid()+"<br/>"+
	                       "<a href='javascript:printRequest("+labRequest.getServerid()+","+labRequest.getTransactionid()+")'><b>"+getTran("web","print",sWebLanguage)+"</b></a>"+
	                      "</td>");
	            out.print("<td>"+MedwanQuery.getInstance().getLabel("web","sampler",sWebLanguage)+"</td>");
	            out.print("<td>"+MedwanQuery.getInstance().getLabel("web","sampletakendatetime",sWebLanguage)+"</td>");
	            out.print("<td>"+MedwanQuery.getInstance().getLabel("web","samplereceptiondatetime",sWebLanguage)+"</td>");
	            out.print("<td>"+MedwanQuery.getInstance().getLabel("web","worklisteddatetime",sWebLanguage)+"</td>");
	            out.print("<td>"+MedwanQuery.getInstance().getLabel("web","technicalvalidator",sWebLanguage)+"</td>");
	            out.print("<td>"+MedwanQuery.getInstance().getLabel("web","technicalvalidationdatetime",sWebLanguage)+"</td>");
	            out.print("<td>"+MedwanQuery.getInstance().getLabel("web","finalvalidator",sWebLanguage)+"</td>");
	            out.print("<td>"+MedwanQuery.getInstance().getLabel("web","finalvalidationdatetime",sWebLanguage)+"</td>");
	        }
	    %>
    </tr>
    <%
        String abnormal = MedwanQuery.getInstance().getConfigString("abnormalModifiers","*+*++*+++*-*--*---*h*hh*hhh*l*ll*lll*");
        DecimalFormat deci = new DecimalFormat("#,###.###");
    
        Iterator groupsIterator = groups.keySet().iterator();
        while(groupsIterator.hasNext()){
            String groupname = (String)groupsIterator.next();
            out.print("<tr class='admin'>"+
                       "<td colspan='"+(requestList.size()+9)+"'><b>"+MedwanQuery.getInstance().getLabel("labanalysis.group",groupname,sWebLanguage)+"</b></td>"+
                      "</tr>");
            
            Hashtable analysisList = (Hashtable)groups.get(groupname);
            Enumeration analysisEnumeration = analysisList.keys();
            while(analysisEnumeration.hasMoreElements()){
                String analysisCode = (String)analysisEnumeration.nextElement();
                String c = analysisCode;
                String u = "";
                String refs = "";
                
                LabAnalysis analysis = LabAnalysis.getLabAnalysisByLabcode(analysisCode);
                if(analysis!=null){
                    c = analysis.getLabId()+"";
                    u = " ("+analysis.getUnit()+")";
                    
                    String min = analysis.getResultRefMin(activePatient.gender,activePatient.getAge());
                    try{
                        float f = Float.parseFloat(min.replace(",","."));
                        min = deci.format(f);
                    }
                    catch(Exception e){
                    	// empty
                    }
                    
                    String max = analysis.getResultRefMax(activePatient.gender,activePatient.getAge());
                    try{
                        float f = Float.parseFloat(max.replace(",","."));
                        max = deci.format(f);
                    }
                    catch(Exception e){
                    	// empty
                    }
                    
                    refs = " ["+min+"-"+max+"]";
                }
                
                requestsIterator = requestList.keySet().iterator();
                if(requestsIterator.hasNext()){
                    labRequest = (LabRequest)requestList.get(requestsIterator.next());
                    
                    RequestedLabAnalysis requestedLabAnalysis = (RequestedLabAnalysis)labRequest.getAnalyses().get(analysisCode);
                    String sEdit = " ";
                    if(activeUser.getAccessRight("labos.worklists.select") && (requestedLabAnalysis.getTechnicalvalidation()>0 || requestedLabAnalysis.getFinalvalidation()>0)){
                    	sEdit = "<img src='"+sCONTEXTPATH+"/_img/icons/icon_edit.gif' onclick='reactivate("+labRequest.getServerid()+","+labRequest.getTransactionid()+",\""+requestedLabAnalysis.getAnalysisCode()+"\")'/>";
                    }
                    out.print("<tr bgcolor='#FFFCD6'><td width='25%' nowrap>"+sEdit+" <b>"+MedwanQuery.getInstance().getLabel("labanalysis",c,sWebLanguage)+" "+u+refs+"</b></td>");
                  
                    String result = (requestedLabAnalysis!=null?requestedLabAnalysis.getFinalvalidation()>0 && requestedLabAnalysis.getResultValue().length()>0?analysis.getLimitedVisibility()>0 && !activeUser.getAccessRight("labos.limitedvisibility.select")?getTran("web","invisible",sWebLanguage):requestedLabAnalysis.getResultValue()+(checkString(requestedLabAnalysis.getResultComment()).length()>0?"<br/>"+requestedLabAnalysis.getResultComment():""):"?":"");
                	if(analysis.getEditor().equalsIgnoreCase("calculated")){
                		String expression = analysis.getEditorparametersParameter("OP").split("\\|")[0];
                		Hashtable pars = new Hashtable();
                		if(analysis.getEditorparameters().split("|").length>0){
                			String[] sPars = analysis.getEditorparametersParameter("OP").split("\\|")[1].replaceAll(" ", "").split(",");
                			for(int n=0;n<sPars.length;n++){
    	        				try{
    	            				pars.put(sPars[n],((RequestedLabAnalysis)labRequest.getAnalyses().get(sPars[n].replaceAll("@", ""))).getResultValue());
    	        				}
    	        				catch(Exception p){}
                			}
                		}
						try{
							result = Evaluate.evaluate(expression, pars,analysis.getEditorparametersParameter("OP").split("\\|").length>2?Integer.parseInt(analysis.getEditorparametersParameter("OP").replaceAll(" ", "").split("\\|")[2]):5);
						}
						catch(Exception e){
                    		result = "?";
						}
                	}
                	else if(analysis.getEditor().equalsIgnoreCase("antivirogram")){
                		String[] arvs = result.split(";");
                		result="";
                		for(int n=0;n<arvs.length;n++){
                			if(arvs[n].split("=").length>1){
                				if(result.length()>0){
                					result+="<br/>";
                				}
                				try{
                					result+=getTran("arv"+arvs[n].split("=")[0].split("\\.")[0],arvs[n].split("=")[0].split("\\.")[1],sWebLanguage)+": "+getTran("arvresistance",arvs[n].split("=")[1],sWebLanguage);
                				}
                				catch(Exception e){}
                			}
                		}
                	}
                	else if(analysis.getEditor().equalsIgnoreCase("antibiogram")||analysis.getEditor().equalsIgnoreCase("antibiogramnew")){
                		result="";
                    	Map ab = RequestedLabAnalysis.getAntibiogrammes(labRequest.getServerid()+"."+labRequest.getTransactionid()+"."+requestedLabAnalysis.getAnalysisCode());
                    	System.out.println("map:"+ab.size());
	                	if(ab.get("germ1")!=null && !(ab.get("germ1")+"").equalsIgnoreCase("")){
	                		result+=ab.get("germ1");
	                	}
	                	if(ab.get("germ2")!=null && !(ab.get("germ2")+"").equalsIgnoreCase("")){
            				if(result.length()>0){
            					result+="<br/>";
            				}
	                		result+=ab.get("germ2");
	                	}
	                	if(ab.get("germ3")!=null && !(ab.get("germ3")+"").equalsIgnoreCase("")){
            				if(result.length()>0){
            					result+="<br/>";
            				}
	                		result+=ab.get("germ3");
	                	}
                	}


                    boolean bAbnormal = (result.length()>0 && !result.equalsIgnoreCase("?") && abnormal.toLowerCase().indexOf("*"+checkString(requestedLabAnalysis.getResultModifier()).toLowerCase()+"*")>-1);
                    
                     out.print("<td nowrap"+(bAbnormal?" bgcolor='#FF8C68'":"")+">"+result+(bAbnormal?" "+checkString(requestedLabAnalysis.getResultModifier().toUpperCase()):"")+"</td>");
                     out.print("<td>"+(requestedLabAnalysis!=null && requestedLabAnalysis.getSampler()>0?MedwanQuery.getInstance().getUserName(requestedLabAnalysis.getSampler()):"")+"</td>");
                     out.print("<td>"+(requestedLabAnalysis!=null && requestedLabAnalysis.getSampletakendatetime()!=null?ScreenHelper.formatDate(requestedLabAnalysis.getSampletakendatetime(),ScreenHelper.fullDateFormat):"")+"</td>");
                     out.print("<td>"+(requestedLabAnalysis!=null && requestedLabAnalysis.getSamplereceptiondatetime()!=null?ScreenHelper.formatDate(requestedLabAnalysis.getSamplereceptiondatetime(),ScreenHelper.fullDateFormat):"")+"</td>");
                     out.print("<td>"+(requestedLabAnalysis!=null && requestedLabAnalysis.getWorklisteddatetime()!=null?ScreenHelper.formatDate(requestedLabAnalysis.getWorklisteddatetime(),ScreenHelper.fullDateFormat):"")+"</td>");
                     out.print("<td>"+(requestedLabAnalysis!=null && requestedLabAnalysis.getTechnicalvalidation()>0?MedwanQuery.getInstance().getUserName(requestedLabAnalysis.getTechnicalvalidation()):"")+"</td>");
                     out.print("<td>"+(requestedLabAnalysis!=null && requestedLabAnalysis.getTechnicalvalidationdatetime()!=null?ScreenHelper.formatDate(requestedLabAnalysis.getTechnicalvalidationdatetime(),ScreenHelper.fullDateFormat):"")+"</td>");
                     out.print("<td>"+(requestedLabAnalysis!=null && requestedLabAnalysis.getFinalvalidation()>0?MedwanQuery.getInstance().getUserName(requestedLabAnalysis.getFinalvalidation()):"")+"</td>");
                     out.print("<td>"+(requestedLabAnalysis!=null && requestedLabAnalysis.getFinalvalidationdatetime()!=null?ScreenHelper.formatDate(requestedLabAnalysis.getFinalvalidationdatetime(),ScreenHelper.fullDateFormat):"")+"</td>");
                    out.print("</tr>");
                }
            }
        }
    %>
</table>

<script>
  function printRequest(serverid,transactionid){
	var url = "<c:url value='/labos/createLabResultsPdf.jsp'/>?ts=<%=getTs()%>&print."+serverid+"."+transactionid+"=1";
    window.open(url,"Popup"+new Date().getTime(),"toolbar=no,status=yes,scrollbars=yes,resizable=yes,width=800,height=600,menubar=no");
  }
  function doBack(){
    window.location.href="<c:url value="/main.do"/>?Page=labos/showLabRequestList.jsp";
  }
  function reactivate(serverid,transactionid,labanalysiscode){
    window.open("<c:url value="/"/>labos/reactivateAnalysis.jsp?serverid="+serverid+"&transactionid="+transactionid+"&labanalysiscode="+labanalysiscode);
  }
</script>