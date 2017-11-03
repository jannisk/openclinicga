<%@page import="be.openclinic.finance.*,
                be.openclinic.statistics.CsvStats,
                be.mxs.common.util.system.HTMLEntities,
                be.mxs.common.util.db.MedwanQuery,
                java.text.SimpleDateFormat,
                java.util.Date"%>
<%@include file="/includes/validateUser.jsp"%>
                
<%
	String label = "labelfr";
	if(sWebLanguage.equalsIgnoreCase("e")||sWebLanguage.equalsIgnoreCase("en")){
		label = "labelen";		
	}

	String sQueryType  = checkString(request.getParameter("query")),
	       sTableType  = checkString(request.getParameter("tabletype")),
	       sTargetLang = checkString(request.getParameter("targetlanguage"));
	
	/// DEBUG /////////////////////////////////////////////////////////////////////////////////////
	if(Debug.enabled){
		Debug.println("\n************************** util/csvStats.jsp **************************");
		Debug.println("label      : "+label);
		Debug.println("sQueryType : "+sQueryType);
		Debug.println("sTableType : "+sTableType+"\n");
	}
	///////////////////////////////////////////////////////////////////////////////////////////////
	
	
    String query = null;
	
	//*** 1 - SERVICE ****************************************************
    if("service.list".equalsIgnoreCase(sQueryType)){
        query = "select upper(OC_LABEL_ID) as CODE, OC_LABEL_VALUE as NAME, b.serviceparentid as PARENT"+
                " from OC_LABELS a, ServicesAddressView b"+
                "  where OC_LABEL_ID = b.serviceid"+
                "   and OC_LABEL_TYPE = 'service'"+
                "   and OC_LABEL_LANGUAGE = '"+sWebLanguage+"'"+
                " order by upper(OC_LABEL_ID)";
    }
	//*** 2 - PATIENTS ***************************************************
    else if("patients.list".equalsIgnoreCase(sQueryType)){
        query = "select a.personid, immatnew as patientid, lastname, firstname, dateofbirth,"+
                "  (select max(district) from privateview where personid=a.personid) as location1,"+
                "  (select max(oc_label_value) from oc_labels,privateview where oc_label_type='province' and oc_label_id=province and personid=a.personid and oc_label_language='"+sWebLanguage+"') as location2"+
                " from adminview a";
    }
	//*** 3 - LABELS *****************************************************
    else if("labels.list".equalsIgnoreCase(sQueryType)){
    	if(ScreenHelper.checkString(sTableType).equalsIgnoreCase("singlelanguage")){
    		if(request.getParameter("language")!=null){
    			query = "select oc_label_type as TYPE,oc_label_id as ID,oc_label_language as LANGUAGE,oc_label_value as LABEL"+
    		            " from oc_labels"+
    					"  where oc_label_language='"+request.getParameter("language")+"'"+
    		            " order by oc_label_type,oc_label_id";
    			Debug.println(query);
    		}
    	}
    	else if(ScreenHelper.checkString(sTableType).equalsIgnoreCase("multilanguage")){
    		if(request.getParameter("language")!=null){
        		String languagecolumns = "";
        		String[] languages = request.getParameter("language").split(",");
        		for(int n=0;n<languages.length;n++){
        			languagecolumns+=",(select max(oc_label_value) from oc_labels where oc_label_type=a.oc_label_type and oc_label_id=a.oc_label_id and oc_label_language='"+languages[n]+"') "+languages[n].toUpperCase();
        		}
    			query = "select a.oc_label_type TYPE,a.oc_label_id ID"+languagecolumns+
    					" from (select distinct oc_label_type,oc_label_id from oc_labels) a"+
    					"  order by oc_label_type,oc_label_id";
    			Debug.println(query);
    		}
    	}
    	else if(ScreenHelper.checkString(sTableType).equalsIgnoreCase("missinglabels")){
    		if(request.getParameter("sourcelanguage")!=null && request.getParameter("targetlanguage")!=null){
        		String languagecolumns = ",(select max(oc_label_value) from oc_labels where oc_label_type=a.oc_label_type and oc_label_id=a.oc_label_id and oc_label_language='"+request.getParameter("targetlanguage")+"') "+request.getParameter("targetlanguage").toUpperCase();
        		String[] languages = request.getParameter("sourcelanguage").split(",");
        		for(int n=0; n<languages.length; n++){
        			languagecolumns+= ",(select max(oc_label_value) from oc_labels where oc_label_type=a.oc_label_type and oc_label_id=a.oc_label_id and oc_label_language='"+languages[n]+"') "+languages[n].toUpperCase();
        		}
    			query = "select a.oc_label_type TYPE,a.oc_label_id ID"+languagecolumns+" from (select distinct oc_label_type,oc_label_id from oc_labels) a where not exists (select * from oc_labels where oc_label_type=a.oc_label_type and oc_label_id=a.oc_label_id and oc_label_value<>'' and oc_label_language='"+request.getParameter("targetlanguage")+"') order by oc_label_type,oc_label_id";
    			Debug.println(query);
    		}
    	}
    }
	//*** 4 - USERS ******************************************************
    else if("user.list".equalsIgnoreCase(sQueryType)){
        query = "select userid as CODE, firstname as FIRSTNAME, lastname as LASTNAME"+
                " from Users a, Admin b"+
                "  where a.personid = b.personid"+
                "   order by userid";
    }
	//*** 5 - PRESTATIONS ************************************************
    else if("prestation.list".equalsIgnoreCase(sQueryType)){
        query = "select OC_PRESTATION_CODE CODE, OC_PRESTATION_DESCRIPTION DESCRIPTION, OC_PRESTATION_PRICE DEFAULTPRICE,"+
                "  OC_PRESTATION_CATEGORIES TARIFFS,OC_PRESTATION_REFTYPE FAMILY,OC_PRESTATION_TYPE TYPE,"+
                "  OC_PRESTATION_INVOICEGROUP INVOICEGROUP,OC_PRESTATION_CLASS CLASS"+
                " from oc_prestations"+
                "  where (OC_PRESTATION_INACTIVE is NULL OR OC_PRESTATION_INACTIVE<>1)"+
                "   ORDER BY OC_PRESTATION_CODE;";
    }
	//*** 6 - DEBETS *****************************************************
    else if("debet.list".equalsIgnoreCase(sQueryType)){
        query = "select oc_debet_date as DATE, lastname as NOM, firstname as PRENOM, oc_prestation_description as PRESTATION,"+
                "  oc_debet_quantity as QUANTITE,"+MedwanQuery.getInstance().convert("int","oc_debet_amount")+" as PATIENT,"+
                   MedwanQuery.getInstance().convert("int","oc_debet_insuraramount")+" as ASSUREUR, oc_label_value as SERVICE,"+
                "  oc_debet_credited as ANNULE,replace(oc_debet_patientinvoiceuid,'1.','') as FACT_PATIENT, oc_encounter_type as ENCOUNTER_TYPE"+
        		" from oc_debets, oc_encounters, adminview, oc_prestations, servicesview, oc_labels"+
        		"  where oc_encounter_objectid = replace(oc_debet_encounteruid,'1.','')"+
        		"   and oc_prestation_objectid = replace(oc_debet_prestationuid,'1.','')"+
        		"   and serviceid = oc_debet_serviceuid"+
        		"   and oc_label_type = 'service'"+
        		"   and oc_label_id = serviceid"+
        		"   and oc_label_language = 'fr'"+
        		"   and oc_encounter_patientuid = personid"+
        		"   and oc_debet_date >= "+MedwanQuery.getInstance().convertStringToDate("'<begin>'")+
        		"   and oc_debet_date <= "+MedwanQuery.getInstance().convertStringToDate("'<end>'")+
        		" ORDER BY oc_debet_date, lastname, firstname";
        		System.out.println(query);
    }
	//*** 6 - DEBETS *****************************************************
    else if("debet.list.per.encounter".equalsIgnoreCase(sQueryType)){
        query = "select count(*) as TOTAL_ENCOUNTERS, "+MedwanQuery.getInstance().convert("int","avg(PATIENT)")+" as PATIENT,"+MedwanQuery.getInstance().convert("int",MedwanQuery.getInstance().getConfigString("stddevFunction","stdev")+"("+MedwanQuery.getInstance().convert("int","PATIENT")+")")+" as PATIENT_STDEV, "+MedwanQuery.getInstance().convert("int","avg(ASSUREUR)")+" as ASSUREUR,"+MedwanQuery.getInstance().convert("int",MedwanQuery.getInstance().getConfigString("stddevFunction","stdev")+"("+MedwanQuery.getInstance().convert("int","ASSUREUR")+")")+" as ASSUREUR_STDEV, "+MedwanQuery.getInstance().convert("int","avg(ASSUREUR_COMPL)")+" as ASSUREUR_COMPL,"+MedwanQuery.getInstance().convert("int",MedwanQuery.getInstance().getConfigString("stddevFunction","stdev")+"("+MedwanQuery.getInstance().convert("int","ASSUREUR_COMPL")+")")+" as ASSUREUR_COMPL_STDEV, ENCOUNTER_TYPE from (select sum("+MedwanQuery.getInstance().convert("int","oc_debet_amount")+") as PATIENT,sum("+
                MedwanQuery.getInstance().convert("int","oc_debet_insuraramount")+") as ASSUREUR,sum("+
                        MedwanQuery.getInstance().convert("int","oc_debet_extrainsuraramount")+") as ASSUREUR_COMPL,oc_encounter_objectid, oc_encounter_type as ENCOUNTER_TYPE"+
        		" from oc_debets, oc_encounters, adminview, oc_prestations, servicesview, oc_labels"+
        		"  where oc_encounter_objectid = replace(oc_debet_encounteruid,'1.','')"+
        		"   and oc_prestation_objectid = replace(oc_debet_prestationuid,'1.','')"+
        		"   and serviceid = oc_debet_serviceuid"+
        		"   and oc_label_type = 'service'"+
        		"   and oc_label_id = serviceid"+
        		"   and oc_label_language = 'fr'"+
        		"   and oc_encounter_patientuid = personid"+
        		"   and oc_debet_date >= "+MedwanQuery.getInstance().convertStringToDate("'<begin>'")+
        		"   and oc_debet_date <= "+MedwanQuery.getInstance().convertStringToDate("'<end>'")+
        		" group BY oc_encounter_objectid,oc_encounter_type) a group by ENCOUNTER_TYPE";
        		System.out.println(query);
    }
	//*** 7 - INVOICES ***************************************************
    else if("hmk.invoices.list".equalsIgnoreCase(sQueryType)){
        Connection loc_conn = MedwanQuery.getInstance().getLongOpenclinicConnection();
		StringBuffer sResult = new StringBuffer();
		
		// search all the invoices from this period     
		query = "select oc_patientinvoice_serverid,oc_patientinvoice_objectid from oc_patientinvoices"+
		        " where oc_patientinvoice_date>="+ MedwanQuery.getInstance().convertStringToDate("'<begin>'")+
		        "  and oc_patientinvoice_date<="+ MedwanQuery.getInstance().convertStringToDate("'<end>'")+
		        "   order by oc_patientinvoice_date";
        query = query.replaceAll("<begin>",request.getParameter("begin"))
        		     .replaceAll("<end>",request.getParameter("end"));
		Debug.println(query);
		PreparedStatement ps = loc_conn.prepareStatement(query);
		ResultSet rs = ps.executeQuery();
		int counter = 1;
		String doctor =checkString(request.getParameter("doctor"));
		String service=checkString(request.getParameter("service"));
	    response.setContentType("application/octet-stream; charset=windows-1252");
	    response.setHeader("Content-Disposition", "Attachment;Filename=\"OpenClinicStatistic"+new SimpleDateFormat("yyyyMMddHHmmss").format(new Date())+".csv\"");
	    
	    ServletOutputStream os = response.getOutputStream();
	    
	    // header
		sResult.append("SERIAL;DATE;PATIENT;AGE;DEPARTMENT;DISEASE;DOCTOR;INSURER;INS_PART;PAT_PART;TOTAL\r\n");
	    
    	byte[] b = sResult.toString().getBytes();
        for(int n=0; n<b.length; n++){
            os.write(b[n]);
        }
        os.flush();
        
		while(rs.next()){
			sResult = new StringBuffer();
			PatientInvoice invoice = PatientInvoice.get(rs.getString("oc_patientinvoice_serverid")+"."+rs.getString("oc_patientinvoice_objectid"));
			if(invoice!=null){
				if(doctor.length()>0 && invoice.getSignatures().indexOf("("+doctor+")")<0){
					continue;
				}
				if(service.length()>0 && !invoice.getServices().contains(service)){
					continue;
				}
				sResult.append(invoice.getUid().split("\\.")[1]+";");
				sResult.append((invoice.getDate()==null?"":ScreenHelper.stdDateFormat.format(invoice.getDate()))+";");
				sResult.append((invoice.getPatient()==null?"":invoice.getPatient().getFullName())+";");
			
				String age = "";
				try{
					int a = invoice.getPatient().getAge();
					if(a<5){
						age = "0->4";
					}
					else if(a<15){
						age = "5->14";
					}
					else {
						age = "15+";
					}
				}
				catch(Exception e){
					// empty
				}
				
				sResult.append(age+";");
				sResult.append(invoice.getServicesAsString(sWebLanguage)+";");
				sResult.append(invoice.getDiseases(sWebLanguage)+";");
				sResult.append(invoice.getSignatures()+";");
				sResult.append(invoice.getInsurers()+";");
				sResult.append(new DecimalFormat(MedwanQuery.getInstance().getConfigString("priceFormat","#")).format(invoice.getInsurarAmount())+";");
				sResult.append((new DecimalFormat(MedwanQuery.getInstance().getConfigString("priceFormat","#")).format(invoice.getPatientAmount()+invoice.getExtraInsurarAmount()))+";");
				sResult.append((new DecimalFormat(MedwanQuery.getInstance().getConfigString("priceFormat","#")).format(invoice.getInsurarAmount()+invoice.getPatientAmount()+invoice.getExtraInsurarAmount()))+";");
				sResult.append("\r\n");
			}
			
	    	b = sResult.toString().getBytes();
	        for(int n=0; n<b.length; n++){
	            os.write(b[n]);
	        }
	        os.flush();
		}
		rs.close();
		ps.close();
		
		loc_conn.close();
        os.close();
    }
	//*** 8 - GLOBAL LIST ************************************************
    else if("global.list".equalsIgnoreCase(sQueryType)){
        Connection loc_conn = MedwanQuery.getInstance().getLongOpenclinicConnection(),
    	           lad_conn = MedwanQuery.getInstance().getLongAdminConnection();
		StringBuffer sResult = null;
		
		// search all encounters from this period
		query = "select * from oc_encounters_view a, adminview b"+
		        " where a.oc_encounter_patientuid = b.personid"+
         		"  and OC_ENCOUNTER_BEGINDATE <= "+MedwanQuery.getInstance().convertStringToDate("'<end>'")+
		        "  and OC_ENCOUNTER_ENDDATE >= "+MedwanQuery.getInstance().convertStringToDate("'<begin>'")+
		        " ORDER BY oc_encounter_objectid";
        query = query.replaceAll("<begin>",request.getParameter("begin"))
        		     .replaceAll("<end>",request.getParameter("end"));
		PreparedStatement ps2 = null;
		ResultSet rs2 = null;
		Debug.println(query);
		PreparedStatement ps = loc_conn.prepareStatement(query);
		ResultSet rs = ps.executeQuery();
		SortedMap results = new TreeMap();
		while(rs.next()){
			String id = rs.getString("oc_encounter_serverid")+"_"+rs.getString("oc_encounter_objectid");

			sResult = new StringBuffer();
			sResult.append(id+";");			
			sResult.append(checkString(rs.getString("oc_encounter_type"))+";");			
			
			java.util.Date dbegin = rs.getDate("oc_encounter_begindate");
			sResult.append(dbegin==null?";":ScreenHelper.stdDateFormat.format(dbegin)+";");		
			
			java.util.Date dend = rs.getDate("oc_encounter_enddate");
			sResult.append(dend==null?";":ScreenHelper.stdDateFormat.format(dend)+";");			
			
			String patientid = checkString(rs.getString("oc_encounter_patientuid"));
			sResult.append(patientid+";");		
			
			java.util.Date dob = rs.getDate("dateofbirth");
			sResult.append(dob==null?";":new SimpleDateFormat("MM/yyyy").format(dob)+";");			
			sResult.append(checkString(rs.getString("gender"))+";");		
		
			try{
				long year = 1000*3600;
				year = year*24*365;
				long age = dbegin.getTime()-dob.getTime();
				age = age/year;
				
				sResult.append(age+";");
			}
			catch(Exception q){
				sResult.append(";");
			}
			
			sResult.append(checkString(rs.getString("oc_encounter_outcome"))+";");		
			sResult.append(checkString(rs.getString("oc_encounter_destinationuid"))+";");		
			sResult.append(checkString(rs.getString("oc_encounter_origin"))+";");
			
			String serviceid = checkString(rs.getString("oc_encounter_serviceuid")).replaceAll("\\.","_");
			sResult.append(serviceid+";");
			
			sResult.append(checkString(rs.getString("oc_encounter_beduid")).replaceAll("\\.","_")+";");
			sResult.append(checkString(rs.getString("oc_encounter_manageruid")).replaceAll("\\.","_")+";");
			sResult.append(checkString(rs.getString("oc_encounter_updateuid")).replaceAll("\\.","_")+";");
			
			results.put(id+";"+patientid+";"+(dbegin==null?"":new SimpleDateFormat("yyyyMMddHHmmsss").format(dbegin))+";"+serviceid,sResult.toString());
		}
		
		Iterator iResults = results.keySet().iterator();
		sResult = new StringBuffer();
		
		// header
		sResult.append("CODE;TYPE;BEGINDATE;ENDDATE;PATIENT_CODE;MONTH_OF_BIRTH;GENDER;AGE;OUTCOME;DESTINATION;ORIGIN;"+
		               "CODE_SERVICE;CODE_BED;CODE_WARDMANAGER;ENCODER;DISTRICT;INSURER;CODE_USER;TYPE;DIAGCODE;LABEL;OLDNEW\r\n");
		
		while(iResults.hasNext()){
			String line = (String)iResults.next();
			String content = (String)results.get(line);
			
			// Add the district
			ps2 = lad_conn.prepareStatement("select * from adminprivate where personid="+line.split(";")[1]);
			rs2 = ps2.executeQuery();
			if(rs2.next()){
				content+= rs2.getString("district")+";";
			}
			else{
				content+= ";";
			}
			rs2.close();
			ps2.close();
			
			// Add insurer
			query = "select max(OC_INSURAR_NAME) as INSURER"+
			        " from OC_INSURARS q, OC_INSURANCES r, OC_DEBETS s"+
			        "  where q.oc_insurar_objectid = replace(r.oc_insurance_insuraruid,'"+MedwanQuery.getInstance().getConfigString("serverId")+".','')"+
			        "   and r.oc_insurance_objectid = replace(s.oc_debet_insuranceuid,'"+MedwanQuery.getInstance().getConfigString("serverId")+".','')"+
			        "   and s.oc_debet_encounteruid='"+line.split(";")[0].replaceAll("\\_", ".")+"'";
			ps2 = loc_conn.prepareStatement(query);
			rs2 = ps2.executeQuery();
			if(rs2.next()){
				content+= checkString(rs2.getString("insurer"))+";";
			}
			else{
				content+= ";";
			}
			rs2.close();
			ps2.close();
			
			// Add reasons for encounter
			ps2 = loc_conn.prepareStatement("select * from OC_DIAGNOSES"+
			                                " where OC_DIAGNOSIS_ENCOUNTERUID='"+line.split(";")[0].replaceAll("\\_", ".")+"'");
			rs2 = ps2.executeQuery();
			
			boolean bHasDiags=false;
			while(rs2.next()){
				bHasDiags = true;
				String codetype = checkString(rs2.getString("OC_DIAGNOSIS_CODETYPE"));
				String code = checkString(rs2.getString("OC_DIAGNOSIS_CODE"));
				
				sResult.append(content+checkString(rs2.getString("OC_DIAGNOSIS_AUTHORUID"))+";"+codetype+";"+code+";"+MedwanQuery.getInstance().getCodeTran((codetype.toLowerCase().startsWith("icpc")?"icpccode":"icd10code")+code, sWebLanguage)+";"+checkString(rs2.getString("OC_DIAGNOSIS_CERTAINTY"))+";"+checkString(rs2.getString("OC_DIAGNOSIS_GRAVITY"))+";\r\n");
			}
			rs2.close();
			ps2.close();
			
			if(!bHasDiags){
				sResult.append(content+";"+";"+";"+";"+";"+"\r\n");
			}
		}
		rs.close();
		ps.close();
		
        loc_conn.close();
        lad_conn.close();
        
	    response.setContentType("application/octet-stream; charset=windows-1252");
	    response.setHeader("Content-Disposition", "Attachment;Filename=\"OpenClinicStatistic"+new SimpleDateFormat("yyyyMMddHHmmss").format(new Date())+".csv\"");
	   
	    ServletOutputStream os = response.getOutputStream();
    	byte[] b = sResult.toString().getBytes();
        for(int n=0; n<b.length; n++){
            os.write(b[n]);
        }
        os.flush();
        os.close();
    }
	//*** 9 - GLOBAL RFE *************************************************
    else if("globalrfe.list".equalsIgnoreCase(sQueryType)){
        Connection loc_conn = MedwanQuery.getInstance().getLongOpenclinicConnection(),
    	           lad_conn = MedwanQuery.getInstance().getLongAdminConnection();
		StringBuffer sResult = null;
		
		// First we search all encounters from this period
		query = "select * from oc_encounters_view a, adminview b where a.oc_encounter_patientuid=b.personid and "+
		        " OC_ENCOUNTER_BEGINDATE<="+ MedwanQuery.getInstance().convertStringToDate("'<end>'")+" AND"+
		        " OC_ENCOUNTER_ENDDATE>="+ MedwanQuery.getInstance().convertStringToDate("'<begin>'")+" ORDER BY oc_encounter_objectid";
        query = query.replaceAll("<begin>",request.getParameter("begin"))
        		     .replaceAll("<end>",request.getParameter("end"));
		PreparedStatement ps2 = null;
		ResultSet rs2 = null;
		PreparedStatement ps = loc_conn.prepareStatement(query);
		ResultSet rs = ps.executeQuery();
		SortedMap results = new TreeMap();
		while(rs.next()){
			sResult = new StringBuffer();
			
			String id = rs.getString("oc_encounter_serverid")+"_"+rs.getString("oc_encounter_objectid");
			sResult.append(id+";");
			
			sResult.append(checkString(rs.getString("oc_encounter_type"))+";");			
			
			java.util.Date dbegin = rs.getDate("oc_encounter_begindate");
			sResult.append(dbegin==null?";":ScreenHelper.stdDateFormat.format(dbegin)+";");		
			
			java.util.Date dend = rs.getDate("oc_encounter_enddate");
			sResult.append(dend==null?";":ScreenHelper.stdDateFormat.format(dend)+";");			
			
			String patientid = checkString(rs.getString("oc_encounter_patientuid"));
			sResult.append(patientid+";");		
			
			java.util.Date dob = rs.getDate("dateofbirth");
			sResult.append(dob==null?";":new SimpleDateFormat("MM/yyyy").format(dob)+";");			
			sResult.append(checkString(rs.getString("gender"))+";");		
			
			try{
				long year = 1000*3600;
				year = year*24*365;
				long age = dbegin.getTime()-dob.getTime();
				age = age/year;
				
				sResult.append(age+";");
			}
			catch(Exception q){
				sResult.append(";");
			}
			
			sResult.append(checkString(rs.getString("oc_encounter_outcome"))+";");		
			sResult.append(checkString(rs.getString("oc_encounter_destinationuid"))+";");		
			sResult.append(checkString(rs.getString("oc_encounter_origin"))+";");
			
			String serviceid = checkString(rs.getString("oc_encounter_serviceuid")).replaceAll("\\.","_");
			sResult.append(serviceid+";");
			
			sResult.append(checkString(rs.getString("oc_encounter_beduid")).replaceAll("\\.","_")+";");
			sResult.append(checkString(rs.getString("oc_encounter_manageruid")).replaceAll("\\.","_")+";");
			sResult.append(checkString(rs.getString("oc_encounter_updateuid")).replaceAll("\\.","_")+";");
			
			results.put(id+";"+patientid+";"+(dbegin==null?"":new SimpleDateFormat("yyyyMMddHHmmsss").format(dbegin))+";"+serviceid,sResult.toString());
		}
		
		Iterator iResults = results.keySet().iterator();
		sResult = new StringBuffer();
		
		// header
		sResult.append("CODE;TYPE;BEGINDATE;ENDDATE;PATIENT_CODE;MONTH_OF_BIRTH;GENDER;AGE;OUTCOME;DESTINATION;"+
		               "ORIGIN;CODE_SERVICE;CODE_BED;CODE_WARDMANAGER;ENCODER;DISTRICT;INSURER;CODE_USER;TYPE;"+
				       "DIAGCODE;LABEL;CERTAINTY;GRAVITY\r\n");
		
		while(iResults.hasNext()){
			String line =(String)iResults.next();
			String content = (String)results.get(line);
		
			// Add the district
			ps2 = lad_conn.prepareStatement("select * from adminprivate where personid="+line.split(";")[1]);
			rs2 = ps2.executeQuery();
			if(rs2.next()){
				content+= rs2.getString("district")+";";
			}
			else{
				content+= ";";
			}
			rs2.close();
			ps2.close();
			
			// Add insurer
			query = "select max(OC_INSURAR_NAME) as INSURER"+
			        " from OC_INSURARS q, OC_INSURANCES r, OC_DEBETS s"+
			        "  where q.oc_insurar_objectid = replace(r.oc_insurance_insuraruid,'"+MedwanQuery.getInstance().getConfigString("serverId")+".','')"+
			        "   and r.oc_insurance_objectid = replace(s.oc_debet_insuranceuid,'"+MedwanQuery.getInstance().getConfigString("serverId")+".','')"+
			        "   and s.oc_debet_encounteruid = '"+line.split(";")[0].replaceAll("\\_", ".")+"'";
			ps2 = loc_conn.prepareStatement(query);
			rs2 = ps2.executeQuery();
			if(rs2.next()){
				content+= checkString(rs2.getString("insurer"))+";";
			}
			else{
				content+= ";";
			}
			rs2.close();
			ps2.close();
			
			// Add reasons for encounter
			ps2 = loc_conn.prepareStatement("select * from OC_RFE where OC_RFE_ENCOUNTERUID='"+line.split(";")[0].replaceAll("\\_", ".")+"'");
			rs2 = ps2.executeQuery();
			boolean bHasRfe = false;
			while(rs2.next()){
				bHasRfe = true;
				
				String codetype = checkString(rs2.getString("OC_RFE_CODETYPE"));
				String code = checkString(rs2.getString("OC_RFE_CODE"));
				
				sResult.append(content+checkString(rs2.getString("OC_RFE_UPDATEUID"))+";"+codetype+";"+code+";"+MedwanQuery.getInstance().getCodeTran((codetype.toLowerCase().startsWith("icpc")?"icpccode":"icd10code")+code, sWebLanguage)+";"+(checkString(rs2.getString("OC_RFE_FLAGS")).indexOf("N")>-1?"NEW":"OLD")+";\r\n");
			}
			rs2.close();
			ps2.close();
			
			if(!bHasRfe){
				sResult.append(content+";"+";"+";"+";"+";"+"\r\n");
			}
		}
		rs.close();
		ps.close();
		
        loc_conn.close();
        lad_conn.close();
        
	    response.setContentType("application/octet-stream; charset=windows-1252");
	    response.setHeader("Content-Disposition","Attachment;Filename=\"OpenClinicStatistic"+new SimpleDateFormat("yyyyMMddHHmmss").format(new Date())+".csv\"");
	   
	    ServletOutputStream os = response.getOutputStream();
    	byte[] b = sResult.toString().getBytes();
        for(int n=0; n<b.length; n++){
            os.write(b[n]);
        }
        os.flush();
        os.close();
    }
	//*** 10 - COUNTERS **************************************************
    else if("encounter.list".equalsIgnoreCase(sQueryType)){
        query = "select "+ MedwanQuery.getInstance().convert("varchar(10)","OC_ENCOUNTER_SERVERID")+MedwanQuery.getInstance().concatSign()+"'_'"+MedwanQuery.getInstance().concatSign()+ MedwanQuery.getInstance().convert("varchar(10)","OC_ENCOUNTER_OBJECTID")+" as CODE,"+
                "  OC_ENCOUNTER_TYPE as TYPE, OC_ENCOUNTER_BEGINDATE as BEGINDATE, OC_ENCOUNTER_ENDDATE as ENDDATE,"+
                "  OC_ENCOUNTER_PATIENTUID as CODE_PATIENT,substring("+MedwanQuery.getInstance().convertDateToString("dateofbirth")+",4,10) as MONTH_OF_BIRTH,"+
                "  gender as GENDER,OC_ENCOUNTER_OUTCOME as OUTCOME, OC_ENCOUNTER_DESTINATIONUID as DESTINATION, OC_ENCOUNTER_ORIGIN as ORIGIN,"+
                "  district as DISTRICT,replace(OC_ENCOUNTER_SERVICEUID,'.','_') as CODE_SERVICE,replace(OC_ENCOUNTER_BEDUID,'.','_') as CODE_LIT,"+
                "  replace(OC_ENCOUNTER_MANAGERUID,'.','_') as CODE_WARD, OC_ENCOUNTER_UPDATEUID as ENCODER"+
		        " from OC_ENCOUNTERS_VIEW, AdminView a, PrivateView b"+
		        "  where OC_ENCOUNTER_PATIENTUID = a.personid"+
		        "   and b.personid = a.personid"+
		        "   and b.stop is null"+
		        "   and OC_ENCOUNTER_BEGINDATE <= "+MedwanQuery.getInstance().convertStringToDate("'<end>'")+
		        "   and OC_ENCOUNTER_ENDDATE >= "+MedwanQuery.getInstance().convertStringToDate("'<begin>'")+
		        " union "+
		        "select "+MedwanQuery.getInstance().convert("varchar(10)","OC_ENCOUNTER_SERVERID")+MedwanQuery.getInstance().concatSign()+"'_'"+MedwanQuery.getInstance().concatSign()+ MedwanQuery.getInstance().convert("varchar(10)","OC_ENCOUNTER_OBJECTID")+" as CODE,"+
		        "  OC_ENCOUNTER_TYPE as TYPE, OC_ENCOUNTER_BEGINDATE as BEGINDATE, OC_ENCOUNTER_ENDDATE as ENDDATE,"+
		        "  OC_ENCOUNTER_PATIENTUID as CODE_PATIENT,substring("+ MedwanQuery.getInstance().convertDateToString("dateofbirth")+",4,10) as MONTH_OF_BIRTH,"+
		        "  gender GENDER,OC_ENCOUNTER_OUTCOME as OUTCOME, OC_ENCOUNTER_DESTINATIONUID as DESTINATION, OC_ENCOUNTER_ORIGIN as ORIGIN,"+
		        "  null as DISTRICT,replace(OC_ENCOUNTER_SERVICEUID,'.','_') as CODE_SERVICE,replace(OC_ENCOUNTER_BEDUID,'.','_') as CODE_LIT,"+
		        "  replace(OC_ENCOUNTER_MANAGERUID,'.','_') as CODE_WARD, OC_ENCOUNTER_UPDATEUID as ENCODER"+
		        " from OC_ENCOUNTERS_VIEW, AdminView a"+
		        "  where OC_ENCOUNTER_PATIENTUID = a.personid"+
		        "   and not exists (select * from PrivateView where personid = a.personid)"+
		        "   and OC_ENCOUNTER_BEGINDATE <= "+ MedwanQuery.getInstance().convertStringToDate("'<end>'")+
		        "   and OC_ENCOUNTER_ENDDATE >= "+MedwanQuery.getInstance().convertStringToDate("'<begin>'")+
                " order by CODE";
    }
	//*** 11 - WICKET CREDITS ********************************************
    else if("wicketcredits.list".equalsIgnoreCase(sQueryType)){
        query = "select oc_wicket_credit_operationdate as DATE,a.oc_label_value as CAISSE,b.oc_label_value as TYPE,"+MedwanQuery.getInstance().convert("int","oc_wicket_credit_amount")+" as MONTANT,"+
                "  oc_wicket_credit_comment as COMMENTAIRE, oc_wicket_credit_invoiceuid as REF_FACTURE,"+
                "  lastname as NOM_UTILISATEUR, firstname as PRENOM_UTILISATEUR"+
        		" from oc_wicket_credits, oc_wickets, oc_labels a, oc_labels b, usersview c, adminview d"+
        		"  where oc_wicket_credit_updateuid = userid"+
        		"   and c.personid = d.personid"+
        		"   and oc_wicket_credit_operationdate >= "+MedwanQuery.getInstance().convertStringToDate("'<begin>'")+
        		"   and oc_wicket_credit_operationdate < "+MedwanQuery.getInstance().convertStringToDate("'<end>'")+
        		"   and oc_wicket_objectid = replace(oc_wicket_credit_wicketuid,'"+MedwanQuery.getInstance().getConfigInt("serverId")+".','')"+
        		"   and a.oc_label_type = 'service'"+
        		"   and a.oc_label_id = oc_wicket_serviceuid"+
        		"   and a.oc_label_language = 'fr'"+
        		"   and b.oc_label_type = 'credit.type'"+
        		"   and b.oc_label_id = oc_wicket_credit_type"+
        		"   and b.oc_label_language = 'fr'"+
        		" order by DATE";
    }
	//*** 12 - DIAGNOSES *************************************************
    else if("diagnosis.list".equalsIgnoreCase(sQueryType)){
        query = "select replace(OC_DIAGNOSIS_ENCOUNTERUID,'.','_') as CODE_CONTACT, OC_DIAGNOSIS_AUTHORUID as CODE_USER,"+
                "  OC_DIAGNOSIS_CODETYPE as TYPE, OC_DIAGNOSIS_CODE as CODE,"+
                "  (CASE OC_DIAGNOSIS_CODETYPE"+
                "    WHEN 'icpc'"+
                "     THEN (select "+label+" from icpc2 where code=OC_DIAGNOSIS_CODE)"+
                "     ELSE (select "+label+" from icd10 where code=OC_DIAGNOSIS_CODE)"+
                "   END) as LABEL,"+
                "  OC_DIAGNOSIS_CERTAINTY as CERTAINTY, OC_DIAGNOSIS_GRAVITY as GRAVITY,"+
                "  replace(OC_ENCOUNTER_SERVICEUID,'.','_') as CODE_SERVICE,"+
                "  replace(OC_ENCOUNTER_BEDUID,'.','_') as CODE_LIT,"+
                "  replace(OC_ENCOUNTER_MANAGERUID,'.','_') as CODE_WARD"+
                " from OC_DIAGNOSES a, OC_ENCOUNTERS_VIEW"+
                "  where OC_DIAGNOSIS_ENCOUNTERUID = "+ MedwanQuery.getInstance().convert("varchar(10)","OC_ENCOUNTER_SERVERID")+MedwanQuery.getInstance().concatSign()+"'.'"+MedwanQuery.getInstance().concatSign()+MedwanQuery.getInstance().convert("varchar(10)","OC_ENCOUNTER_OBJECTID")+
                "   and OC_ENCOUNTER_BEGINDATE <= "+ MedwanQuery.getInstance().convertStringToDate("'<end>'")+
                "   and OC_ENCOUNTER_ENDDATE >= "+ MedwanQuery.getInstance().convertStringToDate("'<begin>'")+
                " order by OC_ENCOUNTER_SERVERID, OC_ENCOUNTER_OBJECTID";
    }
	//*** 13 - RFE *******************************************************
    else if("rfe.list".equalsIgnoreCase(sQueryType)){
        query = "select replace(OC_RFE_ENCOUNTERUID,'.','_') as CODE_CONTACT, OC_RFE_UPDATEUID as CODE_USER,"+
                "  OC_RFE_CODETYPE as TYPE, OC_RFE_CODE as CODE,"+
                "  (CASE OC_RFE_CODETYPE"+
                "    WHEN 'icpc'"+
                "     THEN (select "+label+" from icpc2 where code=OC_RFE_CODE)"+
                "     ELSE (select "+label+" from icd10 where code=OC_RFE_CODE)"+
                "   END) as LABEL,"+
                "  replace(OC_ENCOUNTER_SERVICEUID,'.','_') as CODE_SERVICE,"+
                "  replace(OC_ENCOUNTER_BEDUID,'.','_') as CODE_LIT,"+
                "  replace(OC_ENCOUNTER_MANAGERUID,'.','_') as CODE_WARD"+
                " from OC_RFE a, OC_ENCOUNTERS_VIEW"+
                "  where OC_RFE_ENCOUNTERUID = "+MedwanQuery.getInstance().convert("varchar(10)","OC_ENCOUNTER_SERVERID")+MedwanQuery.getInstance().concatSign()+"'.'"+MedwanQuery.getInstance().concatSign()+MedwanQuery.getInstance().convert("varchar(10)","OC_ENCOUNTER_OBJECTID")+
                "   and OC_ENCOUNTER_BEGINDATE <= "+MedwanQuery.getInstance().convertStringToDate("'<end>'")+
                "   and OC_ENCOUNTER_ENDDATE >= "+MedwanQuery.getInstance().convertStringToDate("'<begin>'")+
                " order by OC_ENCOUNTER_SERVERID, OC_ENCOUNTER_OBJECTID";
    }
	//*** 14 - DOCUMENTS *************************************************
    else if("document.list".equalsIgnoreCase(sQueryType)){
        query = "select c.personid as CODE_PATIENT, a.userId as CODE_USER, a.updatetime as REGISTRATIONDATE, b.oc_label_value as TYPE"+
                " from Transactions a, oc_labels b, Healthrecord c"+
                "  where a.healthrecordid = c.healthrecordid"+
                "   and b.oc_label_type = 'web.occup'"+
                "   and b.oc_label_id = a.transactionType"+
                "   and b.OC_LABEL_LANGUAGE = '"+sWebLanguage+"'"+
                "   and a.updatetime >= "+MedwanQuery.getInstance().convertStringToDate("'<begin>'")+
                "   and a.updatetime <= "+MedwanQuery.getInstance().convertStringToDate("'<end>'")+
                " order by a.updatetime";
    }
    
    Connection loc_conn = MedwanQuery.getInstance().getLongOpenclinicConnection(),
	           lad_conn = MedwanQuery.getInstance().getLongAdminConnection();
    
    Debug.println(query);
    CsvStats csvStats = new CsvStats(request.getParameter("begin"),
    		                         request.getParameter("end"),
    		                         "admin".equalsIgnoreCase(request.getParameter("db"))?lad_conn:loc_conn,
    		                         query);
    
    response.setContentType("application/octet-stream; charset=windows-1252");
    response.setHeader("Content-Disposition", "Attachment;Filename=\"OpenClinicStatistic"+new SimpleDateFormat("yyyyMMddHHmmss").format(new Date())+".csv\"");
   
    ServletOutputStream os = response.getOutputStream();
    byte[] b = csvStats.execute().toString().getBytes();
    for(int n=0; n<b.length; n++){
        os.write(b[n]);
    }
    loc_conn.close();
    lad_conn.close();
    
    os.flush();
    os.close();
%>