<%@page import="java.io.*,java.util.*" %>
<%@page errorPage="/includes/error.jsp"%>
<%@include file="/includes/validateUser.jsp"%>
<%=checkPermission("system.management","all",activeUser)%>

<%!
    //--- CONTAINS KEY ----------------------------------------------------------------------------
    // a properties-object is case sensitive; this function makes it INsensitive.
    public boolean containsKey(Properties properties, String key) {
        Enumeration keys = properties.keys();
        String iniKey;

        while (keys.hasMoreElements()) {
            iniKey = (String) keys.nextElement();
            if (iniKey.equalsIgnoreCase(key)) {
                return true;
            }
        }

        return false;
    }

    //--- GET PROPERTY FILE -----------------------------------------------------------------------
    private Properties getPropertyFile(String sFilename) {
        FileInputStream iniIs;
        Properties iniProps = new Properties();

        // create ini file if they do not exist
        try {
            iniIs = new FileInputStream(sAPPFULLDIR + sFilename);
            iniProps.load(iniIs);
            iniIs.close();
        }
        catch (FileNotFoundException e) {
            // create the file if it does not exist
            try {
                new FileOutputStream(sAPPFULLDIR + sFilename);
            }
            catch (Exception e1) {
                if (Debug.enabled) Debug.println(e1.getMessage());
            }
        }
        catch (Exception e) {
            if (Debug.enabled) Debug.println(e.getMessage());
        }

        return iniProps;
    }
%>
<%
    String action = checkString(request.getParameter("action"));

    // get data from form
    String dataDirection  = checkString(request.getParameter("dataDirection")),
           findLabelType  = checkString(request.getParameter("FindLabelType")),
           findLabelID    = checkString(request.getParameter("FindLabelID")),
           findLabelLang  = checkString(request.getParameter("FindLabelLang")),
           findLabelValue = checkString(request.getParameter("FindLabelValue")),
           findLabelDate  = checkString(request.getParameter("FindLabelDate"));

    // what ini-file to use
    String INIFILENAME = "/_common/xml/Labels.xx.ini";
    if(findLabelLang.length() > 0){
        if(findLabelLang.length() == 2){
            INIFILENAME = INIFILENAME.replaceAll("xx",findLabelLang);
        }
        else{
            throw new Exception("Country must be written in a 2-digit format.");
        }
    }

    // supported languages
    String supportedLanguages = MedwanQuery.getInstance().getConfigString("supportedLanguages");
    if(supportedLanguages.length()==0) supportedLanguages = "nl,fr";

    // excluded label types
    String excludedLabelTypes = MedwanQuery.getInstance().getConfigString("excludedLabelTypesNew");
    if(excludedLabelTypes.length() == 0){
        excludedLabelTypes = "labanalysis, labanalysis.short, labanalysis.monster, labanalysis.refcomment, "+
                             "labprofiles, activitycodes, worktime, patientsharecoverageinsurance, patientsharecoverageinsurance2, "+
                             "urgency.origin ,encountertype ,prestation.type ,product.productgroup, "+
                             "insurance.types ,labanalysis.group ,drug.category"; // default
    }
    excludedLabelTypes = excludedLabelTypes.toLowerCase();
    
    /// DEBUG /////////////////////////////////////////////////////////////////////////////////////
    if(Debug.enabled){
    	Debug.println("\n********************* system.syncLabelsWithIni.jsp *********************");
    	Debug.println("action             : "+action);
    	Debug.println("dataDirection      : "+dataDirection);
    	Debug.println("findLabelType      : "+findLabelType);
    	Debug.println("findLabelID        : "+findLabelID);
    	Debug.println("findLabelLang      : "+findLabelLang);
    	Debug.println("findLabelValue     : "+findLabelValue);
    	Debug.println("findLabelDate      : "+findLabelDate);
    	Debug.println("INIFILENAME        : "+INIFILENAME);
    	Debug.println("supportedLanguages : "+supportedLanguages);
    	Debug.println("excludedLabelTypes : "+excludedLabelTypes+"\n");
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////
%>
<a name="top"/>

<form name="transactionForm" id="transactionForm" method="POST">
<input type="hidden" name="action">
<%=writeTableHeader("Web.manage","SynchronizeLabelsWithIni",sWebLanguage,"main.do?Page=system/menu.jsp")%>

<%-- SELECT ACTION TABLE ------------------------------------------------------------------------%>
<table width="100%" class="menu" cellspacing="1">
    <%-- DATA DIRECTION --%>
    <tr height="30">
        <td colspan="2" class="admin2">
            <input type="radio" name="dataDirection" id="dataDirection1" value="dbToIni" style="cursor:hand" onDblClick="uncheckRadio(this);" <%=(dataDirection.equals("dbToIni")?" checked":"")%>>
            <label for="dataDirection1" style="cursor:hand">In Db, not in ini file (DB to INI)</label>
            &nbsp;&nbsp;&nbsp;&nbsp;
            <input type="radio" name="dataDirection" id="dataDirection2" value="iniToDb" style="cursor:hand" onDblClick="uncheckRadio(this);" <%if(dataDirection.equals("iniToDb")){out.print(" checked");}%>>
            <label for="dataDirection2" style="cursor:hand">In ini file, not in Db (INI to DB)</label>
        </td>
    </tr>
    
    <%-- FROM DATE --%>
    <tr>
        <td class="admin" width="<%=sTDAdminWidth%>">&nbsp;<%=getTran("Web.control","from",sWebLanguage)%></td>
        <td class="admin2"><%=writeDateField("FindLabelDate","transactionForm",findLabelDate,sWebLanguage)%></td>
    </tr>
    
    <%-- LABEL TYPE --%>
    <tr>
        <td class="admin">&nbsp;<%=getTran("Web","type",sWebLanguage)%></td>
        <td class="admin2">
            <select name="FindLabelType" class="text">
                <option></option>
                <%
                    String sTmpLabeltype;
                    String sSelect = "SELECT DISTINCT OC_LABEL_TYPE FROM OC_LABELS ORDER BY OC_LABEL_TYPE";
                    Connection loc_conn = MedwanQuery.getInstance().getLongOpenclinicConnection();
                    PreparedStatement ps = loc_conn.prepareStatement(sSelect);
                    ResultSet rs = ps.executeQuery();

                    while(rs.next()){
                        sTmpLabeltype = checkString(rs.getString("OC_LABEL_TYPE"));
                        %><option value="<%=sTmpLabeltype%>"<%=(sTmpLabeltype.equals(findLabelType)?" selected":"")%>><%=sTmpLabeltype%></option><%
                    }

                    // close DB-stuff
                    if(rs!=null) rs.close();
                    if(ps!=null) ps.close();
                    loc_conn.close();
                %>
            </select>
        </td>
    </tr>
    
    <%-- LABEL ID --%>
    <tr>
        <td class="admin">&nbsp;<%=getTran("Web.Translations","labelid",sWebLanguage)%></td>
        <td class="admin2">
            <input type="text" class="text" name="FindLabelID" value="<%=findLabelID%>" size="<%=sTextWidth%>">
        </td>
    </tr>
    
    <%-- LABEL LANGUAGE --%>
    <tr>
        <td class="admin">&nbsp;<%=getTran("Web","Language",sWebLanguage)%></td>
        <td class="admin2">
            <select name="FindLabelLang" class="text">
                <option value=""><%=getTran("web","choose",sWebLanguage)%></option>
                <%
                    String tmpLang;
                    StringTokenizer tokenizer = new StringTokenizer(supportedLanguages,",");
                    while (tokenizer.hasMoreTokens()){
                        tmpLang = tokenizer.nextToken();
                        %><option value="<%=tmpLang%>" <%=(findLabelLang.equals(tmpLang)?"selected":"")%>><%=getTranNoLink("Web.language",tmpLang,sWebLanguage)%></option><%
                    }
                %>
            </select>
        </td>
    </tr>
    
    <%-- LABEL VALUE --%>
    <tr>
        <td class="admin">&nbsp;<%=getTran("Web.Translations","label",sWebLanguage)%></td>
        <td class="admin2">
            <input type="text" class="text" name="FindLabelValue" value="<%=findLabelValue%>" size="<%=sTextWidth%>">&nbsp;&nbsp;
        </td>
    </tr>
    
    <%-- EXCLUDED TYPES --%>
    <tr height="22">
        <td class="admin">&nbsp;<%=getTran("web.translations","Excludedtypes",sWebLanguage)%></td>
        <td class="admin2"><%=excludedLabelTypes%></td>
    </tr>
    
    <%-- BUTTONS --%>
    <tr>
        <td class="admin">&nbsp;</td>
        <td class="admin2">
            <input type="button" class="button" name="FindButton" value="<%=getTranNoLink("Web","Find",sWebLanguage)%>" onclick="doSubmit('find');">&nbsp;
            <input type="button" class="button" name="ClearButton" value="<%=getTranNoLink("Web","Clear",sWebLanguage)%>" onClick="clearFindFields();">&nbsp;
            <input class="button" type="button" value="<%=getTranNoLink("Web","back",sWebLanguage)%>" onclick="doBack();">
        </td>
    </tr>
</table>

<%
    String select = "";

    // db fields
    String labelValue,
           labelUniqueKey = null,
           updateTime;

    //#############################################################################################
    //### INSERT ##################################################################################
    //#############################################################################################
    if(action.equals("insert")){
        //*** In Db, not in ini (DB to INI) *******************************************************
        String paramName, paramValue;
        String insertMsg = getTran("Web","DataIsSaved",sWebLanguage);

        if(dataDirection.equals("dbToIni")){
            // ADD TO INI FILE
            try{
                FileWriter csvWriter = new FileWriter(sAPPFULLDIR+INIFILENAME,true);
                FileWriter csvWriter2 = new FileWriter(sAPPFULLDIR+INIFILENAME+"new");
                Properties iniProps = getPropertyFile(INIFILENAME);
                Enumeration e = request.getParameterNames();
                while(e.hasMoreElements()){
                    paramName = (String)e.nextElement();
                    paramValue = checkString(request.getParameter(paramName));

                    if(paramName.startsWith("checkbox$") && paramValue.equals("on")){
                        labelUniqueKey = paramName.substring(9).toLowerCase();

                        if(labelUniqueKey.indexOf(" ") < 0 && labelUniqueKey.indexOf("/") < 0 && labelUniqueKey.indexOf(":") < 0){
                            if(!iniProps.containsKey(labelUniqueKey)){
                               select = "SELECT OC_LABEL_VALUE FROM OC_LABELS"+
                                         " WHERE "+MedwanQuery.getInstance().getConfigParam("lowerCompare","OC_LABEL_TYPE")+" NOT IN ('externalservice','service','function')"+
                                         " AND OC_LABEL_TYPE = ?"+
                                         " AND OC_LABEL_ID = ?"+
                                         " AND OC_LABEL_LANGUAGE = ?";

                                loc_conn = MedwanQuery.getInstance().getLongOpenclinicConnection();
                                ps = loc_conn.prepareStatement(select);
                                ps.setString(1,labelUniqueKey.split("\\$")[0]);
                                ps.setString(2,labelUniqueKey.split("\\$")[1]);
                                ps.setString(3,labelUniqueKey.split("\\$")[2]);
                                rs = ps.executeQuery();

                                if(rs.next()){
                                    labelValue = checkString(rs.getString("OC_LABEL_VALUE"));
                                    csvWriter.write(labelUniqueKey+"="+labelValue+"\r\n");
                                    csvWriter.flush();
                                }

                                // close db-stuff
                                if(rs!=null) rs.close();
                                if(ps!=null) ps.close();
                                loc_conn.close();
                            }
                        }
                    }
                }
                csvWriter.close();
                //Now clean the ini-file
                FileReader reader = new FileReader(sAPPFULLDIR+INIFILENAME);
                BufferedReader r = new BufferedReader(reader);
                SortedSet labels = new TreeSet();
				try{
	                while(true){
						String line=r.readLine();
						if(line==null){
							break;
						}
						else if (line.indexOf("$")>0 && line.indexOf("=")>0){
							labels.add(line.trim());
						}
	                }
				}
				catch(IOException eio){
					eio.printStackTrace();	
				}
				r.close();
				
				Iterator i = labels.iterator();
				while(i.hasNext()){
					csvWriter2.write(i.next()+"\r\n");
				}
                csvWriter2.flush();
                csvWriter2.close();
                
                File original = new File(sAPPFULLDIR+INIFILENAME);
                original.delete();
                new File(sAPPFULLDIR+INIFILENAME+"new").renameTo(new File(sAPPFULLDIR+INIFILENAME));
            }
            catch(FileNotFoundException ie){
                ie.printStackTrace();
                insertMsg = "<font color='red'>"+ie.getMessage()+"</font>";
            }
        }
        //*** In ini, not in DB (DB to INI) *******************************************************
        else if(dataDirection.equals("iniToDb")){
            String[] identifiers;
            String sLabelValue;

            Properties iniProps = getPropertyFile(INIFILENAME);

            Enumeration e = request.getParameterNames();
            while(e.hasMoreElements()){
                paramName = (String)e.nextElement();
                paramValue = checkString(request.getParameter(paramName));

                if(paramName.startsWith("checkbox$") && paramValue.equals("on")){
                    identifiers = paramName.split("\\$");
                    sLabelValue = iniProps.getProperty(identifiers[1]+"$"+identifiers[2]+"$"+identifiers[3]);

                    MedwanQuery.getInstance().storeLabel(identifiers[1],identifiers[2],identifiers[3],sLabelValue,0);
                }
            }
            reloadSingleton(session);
        }

        %>
            <br>
            <%=insertMsg%>
        <%
        }
        //#############################################################################################
        //### DELETE ##################################################################################
        //#############################################################################################
        else if(action.equals("delete")){
            Vector recsToBeDeleted = new Vector();
            String paramName, paramValue, lineID;
            String deleteMsg = getTran("Web", "DataIsDeleted", sWebLanguage);

            // PUT ASIDE RECORDS SPECIFIED FOR DELETION IN REQUEST
            Enumeration e = request.getParameterNames();
            while(e.hasMoreElements()){
                paramName = (String) e.nextElement();
                paramValue = checkString(request.getParameter(paramName));

                if(paramName.startsWith("checkbox$") && paramValue.equals("on")){
                    labelUniqueKey = paramName.substring(9).toLowerCase();
                    recsToBeDeleted.add(labelUniqueKey);
                }
            }

            //*** In Db, not in ini (DB to INI) *******************************************************
            if(dataDirection.equals("dbToIni")){
                // DELETE FROM DB
                select = "DELETE FROM OC_LABELS WHERE concat(OC_LABEL_TYPE,'$',OC_LABEL_ID,'$',OC_LABEL_LANGUAGE) = ?";
                loc_conn = MedwanQuery.getInstance().getLongOpenclinicConnection();
                ps = loc_conn.prepareStatement(select);

                for(int i=0; i<recsToBeDeleted.size(); i++){
                    lineID = (String) recsToBeDeleted.get(i);
                    ps.setString(1, lineID);
                    int deletedRecords = ps.executeUpdate();
                    Debug.println("delete : "+lineID.toLowerCase()+" ("+deletedRecords+" deleted)"); 
                }

                ps.close();
                loc_conn.close();
            }
            //*** In ini, not in DB (DB to INI) *******************************************************
            else if (dataDirection.equals("iniToDb")) {
                // DELETE FROM INI FILE
                try {
                    Properties iniProps = getPropertyFile(INIFILENAME);

                    // remove specified labels
                    String label;
                    for (int i = 0; i < recsToBeDeleted.size(); i++) {
                        label = (String) recsToBeDeleted.get(i);
                        iniProps.remove(label);
                    }

                    // write labels to ini file
                    FileOutputStream outputStream = new FileOutputStream(sAPPFULLDIR + INIFILENAME);
                    iniProps.store(outputStream, "Labels." + labelUniqueKey.substring(labelUniqueKey.lastIndexOf("$") + 1) + ".ini");
                    outputStream.close();
                }
                catch (FileNotFoundException de) {
                    de.printStackTrace();
                    deleteMsg = "<font color='red'>" + de.getMessage() + "</font>";
                }
            }

        %>
            <br>
            <%=deleteMsg%>
        <%
        
        reloadSingleton(session);
    }
    //#############################################################################################
    //### FIND (DISPLAY DIFFERENCES BETWEEN INI AND DB) ###########################################
    //#############################################################################################
    else if(action.equals("find")){
        %>
            <br>

            <%-- BUTTONS at TOP -----------------------------------------------------------------%>
            <table width="100%" cellspacing="1">
                <tr>
                    <td>
                        <a href="javascript:checkAll(true);"><%=getTran("Web.Manage.CheckDb","CheckAll",sWebLanguage)%></a>
                        <a href="javascript:checkAll(false);"><%=getTran("Web.Manage.CheckDb","UncheckAll",sWebLanguage)%></a>
                    </td>
                    <td align="right">
                        <a href='#bottom'><img src='<c:url value='/_img/themes/default/bottom.gif'/>' class='link' border="0"></a>
                    </td>
                </tr>
            </table>
            <%-- DISPLAY RECORDS ----------------------------------------------------------------%>
            <table width="100%" class="list" cellspacing="1" onMouseOver='this.style.cursor="hand"' onMouseOut='this.style.cursor="default"'>
                <tr><td width="16"/><td/><td width="99%"/></tr>
                <%
                    int labelCount = 0, invalidLabelCount = 0;
                    Properties iniProps = getPropertyFile(INIFILENAME);

                    //*** In DB, not in ini (DB TO INI) *******************************************
                    if(dataDirection.equals("dbToIni")){
                        String sClass = "1", checked, labelType, labelID, labelLang;

                        select = "SELECT * FROM OC_LABELS"+
                                 " WHERE "+MedwanQuery.getInstance().getConfigParam("lowerCompare","OC_LABEL_TYPE")+" NOT IN ('externalservice','service','function') ";

                        if(findLabelType.length()>0) {
                            select+= "AND "+MedwanQuery.getInstance().getConfigParam("lowerCompare","OC_LABEL_TYPE")+" = '"+ScreenHelper.checkDbString(findLabelType).toLowerCase()+"' ";
                        }

                        if(findLabelID.length()>0) {
                            select+= "AND "+MedwanQuery.getInstance().getConfigParam("lowerCompare","OC_LABEL_ID")+" LIKE '%"+ScreenHelper.checkDbString(findLabelID).toLowerCase()+"%' ";
                        }

                        if(findLabelLang.length()>0) {
                            select+= "AND "+MedwanQuery.getInstance().getConfigParam("lowerCompare","OC_LABEL_LANGUAGE")+" = '"+ScreenHelper.checkDbString(findLabelLang).toLowerCase()+"' ";
                        }

                        if(findLabelValue.length()>0) {
                            select+= "AND "+MedwanQuery.getInstance().getConfigParam("lowerCompare","OC_LABEL_VALUE")+" LIKE '%"+ScreenHelper.checkDbString(findLabelValue).toLowerCase()+"%' ";
                        }

                        if(findLabelDate.length()>0){
                            select+= "AND OC_LABEL_UPDATETIME >= ? ";
                        }

                        select+= "ORDER BY OC_LABEL_UPDATETIME DESC, OC_LABEL_TYPE, OC_LABEL_ID";

                        loc_conn = MedwanQuery.getInstance().getLongOpenclinicConnection();
                        ps = loc_conn.prepareStatement(select);

                        if(findLabelDate.length() > 0){
                            java.util.Date labelUpdateTime = ScreenHelper.fullDateFormatSS.parse(findLabelDate+" 00:00:00");
                            ps.setTimestamp(1,new Timestamp(labelUpdateTime.getTime()));
                        }
                        rs = ps.executeQuery();

                        // invalid key chars
                        String invalidLabelKeyChars = MedwanQuery.getInstance().getConfigString("invalidLabelKeyChars");
                        if(invalidLabelKeyChars.length() == 0){
                            invalidLabelKeyChars = " /:"; // default
                        }

                        while(rs.next()){
                            labelType      = checkString(rs.getString("OC_LABEL_TYPE"));
                            labelID        = checkString(rs.getString("OC_LABEL_ID"));
                            labelLang      = checkString(rs.getString("OC_LABEL_LANGUAGE"));
                            labelUniqueKey = (labelType+"$"+labelID+"$"+labelLang).toLowerCase();

                            // only display labels if not in ini, so check existence in ini.
                            if(excludedLabelTypes.indexOf(labelType.toLowerCase())<0 && !containsKey(iniProps,labelUniqueKey) && labelID.indexOf(" ")<0){
                                // display labels, except excluded labeltypes
                                checked = "checked";

                                if(excludedLabelTypes.indexOf(labelType.toLowerCase()) < 0){
                                    labelValue = checkString(rs.getString("OC_LABEL_VALUE"));
                                    if(labelValue.length()==0) labelValue = "<font color='red'>[empty]</font>";

                                    updateTime = ScreenHelper.getSQLDate(rs.getDate("OC_LABEL_UPDATETIME"));
                                    labelCount++;

                                    // alternate row-class
                                    sClass = (labelCount%2==0?"":"1");

                                    // red background for invalid key-names
                                    for(int i=0; i<invalidLabelKeyChars.length(); i++){
                                        if(labelUniqueKey.indexOf(invalidLabelKeyChars.charAt(i)) > -1){
                                        	sClass = "red\" style='background:#ff6666';";
                                            invalidLabelCount++;
                                            checked = "";
                                            break;
                                        }
                                    }

                                    %>
                                        <tr class="list<%=sClass%>">
                                            <td>
                                                <input type="checkbox" id="cb<%=labelCount%>" name="checkbox$<%=labelUniqueKey%>" <%=checked%>>
                                            </td>
                                            <td onclick="setCB('cb<%=labelCount%>');">
                                                DATE&nbsp;<br>
                                                TYPE&nbsp;<br>
                                                ID&nbsp;<br>
                                                VALUE&nbsp;
                                            </td>
                                            <td onclick="setCB('cb<%=labelCount%>');">
                                                <%=updateTime%><br>
                                                <%=labelType%><br>
                                                <b><%=labelID%></b><br>
                                                <%=labelValue%>
                                            </td>
                                        </tr>
                                    <%
                                                }
                                            }
                                        }

                                        // close db-stuff
                                        if (rs != null) rs.close();
                                        if (ps != null) ps.close();
                                        loc_conn.close();
                                    }
                                    //*** In ini, not in DB (INI to DB) *******************************************
                                    else if (dataDirection.equals("iniToDb")) {
                                        String sLabelType, sLabelID, sLabelLang, sLabelValue, sLabelUniqueKey;
                                        labelCount = 0;
                                        String style;

                                        Hashtable labels = MedwanQuery.getInstance().getLabels();
                                        Enumeration e = iniProps.propertyNames();

                                        select = "SELECT 1 FROM OC_LABELS WHERE OC_LABEL_TYPE=? AND OC_LABEL_ID=? AND OC_LABEL_LANGUAGE=?";
                                        loc_conn = MedwanQuery.getInstance().getLongOpenclinicConnection();
                                        ps = loc_conn.prepareStatement(select);

                                        while (e.hasMoreElements()) {
                                            sLabelUniqueKey = (String) e.nextElement();

                                            if (sLabelUniqueKey.indexOf("$") > 0) {
                                                String[] identifiers = sLabelUniqueKey.split("\\$");
                                                sLabelType = identifiers[0].toLowerCase();
                                                sLabelID = identifiers[1].toLowerCase();
                                                sLabelLang = identifiers[2].toLowerCase();

                                                // only check existence in DB of those labels that do not occur in the label hash
                                                // check at 3 levels of hashes
                                                if (excludedLabelTypes.indexOf(sLabelType.toLowerCase())<0 && (labels.get(sLabelLang) == null || ((Hashtable) labels.get(sLabelLang)).get(sLabelType) == null ||
                                                        ((Hashtable) ((Hashtable) labels.get(sLabelLang)).get(sLabelType)).get(sLabelID) == null)) {
                                                    // only list record if not in DB, so check existence in DB
                                                    ps.setString(1, sLabelType);
                                                    ps.setString(2, sLabelID);
                                                    ps.setString(3, sLabelLang);
                                                    rs = ps.executeQuery();

                                                    if (!rs.next()) {
                                                        sLabelValue = iniProps.getProperty(sLabelUniqueKey);
                                                        labelCount++;
                                                        style = (labelCount % 2 == 0 ? "1" : "");

                                        %>
                                            <tr class="list<%=style%>" >
                                                <td><input type="checkbox" id="cb<%=labelCount%>" name="checkbox$<%=sLabelUniqueKey%>"></td>
                                                <td onclick="setCB('cb<%=labelCount%>');">
                                                    TYPE&nbsp;<br>
                                                    ID&nbsp;<br>
                                                    VALUE&nbsp;
                                                </td>
                                                <td onclick="setCB('cb<%=labelCount%>');">
                                                    <%=sLabelType%><br>
                                                    <b><%=sLabelID%></b><br>
                                                    <%=sLabelValue%>
                                                </td>
                                            </tr>
                                        <%
                                    }
                                }
                            }
                        }

                        // close db-stuff
                        if(rs!=null) rs.close();
                        if(ps!=null) ps.close();
                        loc_conn.close();
                    }
                %>
            </table>
            
            <script>
              function setCB(id){
                var cb = document.getElementById(id);
                if(cb.checked) cb.checked = false;
                else                 cb.checked = true;
              }
            </script>
            
            <%-- BUTTONS at BOTTOM --------------------------------------------------------------%>
            <table width="100%" cellspacing="1">
                <tr>
                    <td>
                        <a href="javascript:checkAll(true);"><%=getTran("Web.Manage.CheckDb","CheckAll",sWebLanguage)%></a>
                        <a href="javascript:checkAll(false);"><%=getTran("Web.Manage.CheckDb","UncheckAll",sWebLanguage)%></a>
                    </td>
                    <td align="right">
                        <a href='#topp'><img src='<c:url value='/_img/themes/default/top.gif'/>' class='link' border="0"></a>
                    </td>
                </tr>
                <%-- BUTTONS --%>
                <tr>
                    <td colspan="2">
                        <%=ScreenHelper.alignButtonsStart()%>
                        <input type="button" class="button" name="InsertButton" value="<%=getTranNoLink("Web","Add",sWebLanguage)%>" onclick="doSubmit('insert')">
                        <input type="button" class="button" name="DeleteButton" value="<%=getTranNoLink("Web","Delete",sWebLanguage)%>" onclick="doSubmit('delete')">
                        <%=ScreenHelper.alignButtonsStop()%>
                    </td>
                </tr>
                <%-- NUMBER OF LABELS FOUND --%>
                <tr>
                    <td colspan="2">
                        <%=labelCount%> <%=getTran("Web.Manage","labelsFound",sWebLanguage)%><br>
                        <%=invalidLabelCount%> <%=getTran("Web.Manage","invalidLabelsFound",sWebLanguage)%>
                    </td>
                </tr>
            </table>
        <%
    }

    // close db-stuff
    if(rs!=null) rs.close();
    if(ps!=null) ps.close();
    loc_conn.close();
%>
</form>

<%-- link to manage translations --%>
<%=ScreenHelper.alignButtonsStart()%>
    <img src='<c:url value="/_img/themes/default/pijl.gif"/>'>
    <a  href="<c:url value='/main.do'/>?Page=system/manageTranslations.jsp?ts=<%=getTs()%>" onMouseOver="window.status='';return true;"><%=getTran("Web","managetranslations",sWebLanguage)%></a>&nbsp;
<%=ScreenHelper.alignButtonsStop()%>

<a name="bottom">&nbsp;<a/>

<%-- SCRIPTS ------------------------------------------------------------------------------------%>
<script>
  function doSubmit(action){
    if(action=="insert"){
      for(i=0; i<transactionForm.elements.length; i++){
        if(transactionForm.elements[i].type=="checkbox" && transactionForm.elements[i].name.indexOf("checkbox$")>-1){
          if(transactionForm.elements[i].checked){
            transactionForm.action.value = action;
            transactionForm.submit();
            break;
          }
        }
      }
    }
    else if(action=="find"){
      if(transactionForm.FindLabelLang.selectedIndex > 0){
        if((document.getElementById('dataDirection1').checked) || (document.getElementById('dataDirection2').checked)){
          transactionForm.action.value = action;
          transactionForm.submit();
        }
        else{
          alertDialog("web.manage","chooseDataDirection");
        }
      }
      else{
    	transactionForm.FindLabelLang.focus();
    	alertDialog("web.manage","dataMissing");
      }
    }
    else if(action=="delete"){
      for(i=0; i<transactionForm.elements.length; i++){
        if(transactionForm.elements[i].type=="checkbox" &&
          transactionForm.elements[i].name.indexOf("checkbox$")>-1){
          if(transactionForm.elements[i].checked){
              if(yesnoDeleteDialog()){
              transactionForm.action.value = action;
              transactionForm.submit();
            }
            break;
          }
        }
      }
    }
    else{
      transactionForm.action.value = action;
      transactionForm.submit();
    }
  }

  function checkAll(setchecked){
    for(i=0; i<transactionForm.elements.length; i++){
      if(transactionForm.elements[i].type=="checkbox"){
        transactionForm.elements[i].checked = setchecked;
      }
    }
  }

  function clearFindFields(){
    transactionForm.FindLabelType.selectedIndex = 0;
    transactionForm.FindLabelDate.value = "";
    transactionForm.FindLabelID.value = "";
    transactionForm.FindLabelLang.selectedIndex = 0;
    transactionForm.FindLabelValue.value = "";
  }
  
  function doBack(){
    window.location.href = "<c:url value='/main.do'/>?Page=system/menu.jsp";
  }
</script>