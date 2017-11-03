package org.hnrw.chin;

import be.mxs.common.util.db.MedwanQuery;
import be.mxs.common.util.system.Internet;
import java.io.BufferedOutputStream;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Vector;
import java.io.FileWriter;
import java.io.IOException;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.ResultSet;
import java.net.URL;
import java.net.MalformedURLException;
import org.apache.commons.net.ftp.FTPClient;
import org.apache.commons.net.ftp.FTPFile;

import org.dom4j.Element;
import org.dom4j.DocumentHelper;
import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.io.SAXReader;
import org.hnrw.chin.integrators.Integrator;

/**
 * Created by IntelliJ IDEA.
 * User: Frank
 * Date: 23-mei-2008
 * Time: 20:26:31
 * To change this template use File | Settings | File Templates.
 */
public class MessageManager {

    public static boolean readMessages(){
        boolean bSuccess=false;
        Connection oc_conn=MedwanQuery.getInstance().getOpenclinicConnection();
        try{
            String sQuery="select * from HealthNetIntegratedMessages where integrationDateTime is null order by hn_filename desc";
            PreparedStatement psList = oc_conn.prepareStatement(sQuery);
            ResultSet rs = psList.executeQuery();
            while(rs.next()){
                Integrator.readMessage(rs.getString("hn_filename"));
            }
            rs.close();
            psList.close();
            bSuccess=true;
        }
        catch(Exception e){
            e.printStackTrace();
        }
        try {
			oc_conn.close();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
        return bSuccess;
    }

    public static boolean receiveMessages(){
        boolean bSuccess=false;
        String sDoc = MedwanQuery.getInstance().getConfigString("templateSource") + "healthnet.xml";
        SAXReader reader = new SAXReader(false);
        try {
            Document hnConfig = reader.read(new URL(sDoc));
            Element root=hnConfig.getRootElement();
            Element server = root.element("server");
            Element integrator = root.element("integrator");
            FTPClient ftp = new FTPClient();
            int retries = 0;
            while (!ftp.isConnected()&& retries < 1) {
                retries++;
                try {
                    if (Internet.isReachable(server.attributeValue("host"), Integer.parseInt(server.attributeValue("port","21")), 1000)) {
                        ftp.connect(server.attributeValue("host"),Integer.parseInt(server.attributeValue("port","21")));
                        break;
                    }
                }
                catch (Exception e) {
                }
            }
            if (ftp.isConnected()) {
                ftp.login(server.attributeValue("user"),server.attributeValue("password"));
               ftp.setFileType(org.apache.commons.net.ftp.FTP.BINARY_FILE_TYPE);
                //Nu moeten we alle berichtjes downloaden die op de server beschikbaar zijn
                FTPFile[] files = ftp.listFiles();
                for (FTPFile file : files) {
                //for(int n=0;n<files.length();n++){
                    
                   // String[] s = ((String)files.elementAt(n)).split(" ");
                    String filename=file.getName(); //s[s.length-1];
                    File downloadFile1 = new File((integrator.attributeValue("directory","c:/hn/received")+"/"+filename).replaceAll("//","/"));
                    OutputStream outputStream1 = new BufferedOutputStream(new FileOutputStream(downloadFile1));
                    ftp.retrieveFile(filename,outputStream1);
                    Document msg = reader.read((integrator.attributeValue("directory","c:/hn/received")+"/"+filename).replaceAll("//","/"));
                    Element msgroot=msg.getRootElement();
                    //Update hn message table
                    String sQuery="insert into HealthNetIntegratedMessages(hn_filename,receivedDateTime,type,hn_source)" +
                            " values(?,?,?,?)";
                    Connection oc_conn=MedwanQuery.getInstance().getOpenclinicConnection();
                    PreparedStatement ps = oc_conn.prepareStatement(sQuery);
                    ps.setString(1,filename);
                    ps.setTimestamp(2,new Timestamp(new Date().getTime()));
                    ps.setString(3,msgroot.attributeValue("type"));
                    ps.setString(4,msgroot.attributeValue("source"));
                    ps.execute();
                    ps.close();
                    oc_conn.close();
                    ftp.deleteFile(filename);
                }
                ftp.disconnect();
                bSuccess=true;
            }

        }
        catch(Exception e){
            e.printStackTrace();
        }
        return bSuccess;
    }

    public static boolean sendMessages(boolean delete){
        boolean bSuccess=false;
        String sDoc = MedwanQuery.getInstance().getConfigString("templateSource") + "healthnet.xml";
        SAXReader reader = new SAXReader(false);
        Connection oc_conn=MedwanQuery.getInstance().getOpenclinicConnection();
        try {
            Document hnConfig = reader.read(new URL(sDoc));
            Element root=hnConfig.getRootElement();
            Element server = root.element("server");
            FTPClient ftp = new FTPClient();
            Element storage = root.element("storage");
            Element client = root.element("client");
            String sQuery="select * from HealthNetMessages where sendDateTime is null";
            PreparedStatement psList = oc_conn.prepareStatement(sQuery);
            ResultSet rs = psList.executeQuery();
            boolean initialized=false;
            while(rs.next()){
                try{
                    if(!initialized){
                        int retries = 0;
                        while (!ftp.isConnected()&& retries < 1) {
                            retries++;
                            try {
                                if (Internet.isReachable(server.attributeValue("host"), Integer.parseInt(server.attributeValue("port","21")), 1000)) {
                                    ftp.connect(server.attributeValue("host"),Integer.parseInt(server.attributeValue("port","21")));
                                    break;
                                }
                            }
                            catch (Exception e) {
                            }
                        }
                        if (ftp.isConnected()) {
                            ftp.login(server.attributeValue("user"),server.attributeValue("password"));
                            ftp.setFileType(org.apache.commons.net.ftp.FTP.BINARY_FILE_TYPE);
                            initialized=true;
                        }
                    }
                    if(initialized){
                        String firstRemoteFile = "Projects.zip";
                      
                        String filename=rs.getString("hn_filename");
                        InputStream inputStream = new FileInputStream(client.attributeValue("id")+"."+filename.replaceAll(storage.attributeValue("directory","c:/hn/messages"),"").replaceAll("/",""));
                        ftp.storeFile(filename, inputStream);
                        inputStream.close();
                        sQuery="update HealthNetMessages set sendDateTime=? where hn_filename=?";
                        PreparedStatement ps = oc_conn.prepareStatement(sQuery);
                        ps.setTimestamp(1,new Timestamp(new Date().getTime()));
                        ps.setString(2,filename);
                        ps.execute();
                        ps.close();
                        if(delete){
                            new File(filename).delete();
                        }
                    }
                }
                catch(Exception e1){
                    e1.printStackTrace();
                }
            }
            rs.close();
            psList.close();

            if(initialized){
                ftp.disconnect();
            }
            bSuccess=true;
        } catch (Exception e) {
            e.printStackTrace();
        }
        try {
			oc_conn.close();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

        return bSuccess;
    }

    public static boolean storeMessage(Element message){
        boolean bSuccess=false;
        Connection oc_conn=MedwanQuery.getInstance().getOpenclinicConnection();
        try {
            String sDoc = MedwanQuery.getInstance().getConfigString("templateSource") + "healthnet.xml";
            SAXReader reader = new SAXReader(false);
            Document hnConfig = reader.read(new URL(sDoc));
            Element root=hnConfig.getRootElement();
            Element storage = root.element("storage");
            Element client = root.element("client");
            message.addAttribute("source",client.attributeValue("id"));
            String filename = storage.attributeValue("directory","c:/hn/messages")+"/"+ message.attributeValue("created")+".hn.msg";
            filename = filename.replaceAll("//","/");
            Document document = DocumentHelper.createDocument(message);
            //Write message to file
            FileWriter fileWriter = new FileWriter(filename);
            document.write(fileWriter);
            fileWriter.flush();
            fileWriter.close();
            //Update hn message table
            String sQuery="insert into HealthNetMessages(hn_filename,creationDateTime)" +
                    " values(?,?)";
            PreparedStatement ps = oc_conn.prepareStatement(sQuery);
            ps.setString(1,filename);
            ps.setTimestamp(2,new Timestamp(new SimpleDateFormat("yyyyMMddHHmmssSSS").parse(message.attributeValue("created")).getTime()));
            ps.execute();
            ps.close();
            bSuccess=true;
        } catch (Exception e) {
            e.printStackTrace();
        }
        try {
			oc_conn.close();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
        return bSuccess;
    }

}
