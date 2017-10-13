<%@ WebHandler Language="C#" Class="zixunApi" %>

using DBUtility;
using System;
using System.Web.UI;
using System.Data;
using System.Text;
using System.Web;
using System.Web.Services;
using System.Web.SessionState;

using System.Collections;
using System.Collections.Generic;
using System.Runtime.Serialization.Json;
using System.Xml.Linq;
using System.IO;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Linq;
using System.Text;
using System.Net;
//grid13咨询表
public class zixunApi : IHttpHandler
{
    //string openid = "";
    //string session_key = "";
    public void ProcessRequest(HttpContext context)
    {
        // admininfo      getCount   sales   pubi  shouyi ASEN(xuqiuAll、xuqiuSelect、xuqiuEdit、xuqiuNew )
        //"{\"total\":-1, \"rows\":[{ \"id\":\"1\"}]}"
        //"{\"session_key\":\"l3RfWsKbrPKuWRg+Y\\/2t1Q==\",\"expires_in\":7200,\"openid\":\"oTn3-0IzfVLUDcLWVF_340hQZ8Wg\"}"
        string openid = "";
        //context.Response.ContentType = "text/plain";
        context.Response.ContentType = "application/json"; ;
        string action = context.Request.Params["action"];

        int page = 1;
        int pagesize = 5;
        //string strid = context.Request.Params["id"];
        //string openId = context.Request.Params["openId"];
        BaseClass bc = new BaseClass();
        StringBuilder st = new StringBuilder();
        //string getReturn = "";
        int idNew = 0;
        int intId = 0;
        string shijian = "";
        string shijian2 = "";
        string sqlUpdate = "";
        //string sqlRecord = "";
        DataAction DA = new DataAction();
        int coutt = 0;
        //a 第一次登陆后，小程序获得了openId，
        //b 以后每次请求，需要先获得小程序的openId（加密了的，需解密Decode）
        openid = context.Request.Params["openId"];
        PublicCla p = new PublicCla();
        openid = p.Decode(openid);
        //c 通过用户登陆openid,获取到登陆用户的aId：intId
        intId = getId2(openid);
        if (intId == 0)
        {
            context.Response.Write("false");
            return;
        }
        
        //先判断这个账号5分钟之内是否登陆过，如果是  openid——要根据小程序端解析获取
        //shijian = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        //shijian2 = DateTime.Now.AddMinutes(-10).ToString("yyyy-MM-dd HH:mm:ss"); //加n分                  
        //sqlRecord = "select * from record  where openId='" + openid + "' and shijian<'" + shijian + "' and shijian>'" + shijian2 + "'";
        //DataTable dtRecord2 = bc.ReadTable(sqlRecord);
        //if (dtRecord2.Rows.Count == 0)
        //{
        //    string strError="{\"error\":\"非正常登陆\"}";
        //    context.Response.Write(strError);

        //    return;
        //}

        //1.获取登录用户，条件："a.aId = " + intId
        if (action == "userinfo")
        {//api/zixunApi.ashx?action=userinfo&openid=YjFSdU15MHdTWHBtVmt4VlJHTk1WMVpHWHpNME1HaFJXamhYWnc9PQ==
            string sqll = " where 1=1  ";
            sqll = sqll + " and a.aId = " + intId + "";
            string sqlwhat = " a.aId,a.aNum,a.aName,a.aSex,a.aPhone,a.aUsername,a.aPwd,a.aDnum,a.aRnum,a.aSnum,a.aIfuser,a.aDate,a.province,a.city,a.aAddress,a.aWeixin,a.aTuijian,a.aYue,a.aPubi,a.xId ";
            string strAll = " select " + sqlwhat + " from admininfo a  " + sqll;
            coutt = PublicMethod.QueryDataset(strAll).Tables[0].Rows.Count;
            DataTable dt = PublicMethod.FindForPageAll(page, pagesize, sqll, " admininfo a ", "a.aId", sqlwhat);
            if (dt.Rows.Count > 0)
            {
                PublicCla c2 = new PublicCla();
                context.Response.Write(c2.CreateJsonParameters2(dt, coutt));
            }
            else
            {
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[]}");
            }
            return;
        }



        //7.咨询列表grid13，条件："a.aId = " + intId
        if (action == "zixunAll")
        {//api/zixunApi.ashx?action=zixunAll&openid=SW05VWJqTXRNRWw2WmxaTVZVUmpURmRXUmw4ek5EQm9VVm80Vnc9PQ==&sousuo=,
            //string sqll = " where 1=1  and a.xId=b.xId  ";
            string sousuo = context.Request.Params["sousuo"];
            string[] sousuo2 = sousuo.Split(new char[] { ',' });
            string Neirong = sousuo2[0];
            string jieguo = sousuo2[1];
            string sqll = " where 1=1    ";
            sqll = sqll + " and a.aId = " + intId;
            if (Neirong != "")
            {
                sqll = sqll + " and a.Neirong like '%" + Neirong + "%'";
            }
            if (jieguo != "" && jieguo != "全部")
            {
                if (jieguo == "已解决")
                {
                    sqll = sqll + " and a.jieguo ='" + jieguo + "' ";
                }
                else
                {
                    sqll = sqll + " and a.jieguo <>'已解决' ";
                }
            }   
   
            
            shijian = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            shijian2 = (int.Parse(shijian.Substring(0, 4)) - 1).ToString() + shijian.Substring(4, 15);

            //string sqlwhat1 = " select  a.id,a.num,a.name,a.aId,a.xId,a.leixing,a.mudi,a.jieguo,a.Tianxie,a.shenhe,a.shijian,LEFT(a.shijian,7) as yuefen,b.sName    from  grid13 a,grid00 b    ";
            //string sqlwhat2 = " union select COUNT(a.id),'0','0','0','0','0','0','0','0','0','2050',LEFT(a.shijian,7),'' as yuefen  from  grid13 a,grid00 b  ";
            //string strAll = sqlwhat1 + sqll + sqlwhat2 + sqll + " group by LEFT(a.shijian,7) order by yuefen desc,a.shijian desc  ";

            string sqlwhat1 = " select  a.id,a.num,a.name,a.aId,a.xId,a.leixing,a.Neirong,a.mudi,a.jieguo,a.Tianxie,a.shenhe,a.shijian,LEFT(a.shijian,7) as yuefen from  grid13 a    ";
            string sqlwhat2 = " union select COUNT(a.id),'0','0','0','0','0','0','0','0','0','0','2050',LEFT(a.shijian,7) as yuefen  from  grid13 a  ";
            string strAll = sqlwhat1 + sqll + sqlwhat2 + sqll + " group by LEFT(a.shijian,7) order by yuefen desc,a.shijian desc  ";
            DataTable dt = bc.ReadTable(strAll);
            if (dt.Rows.Count > 0)
            {
                PublicCla c2 = new PublicCla();
                context.Response.Write(c2.CreateJsonParameters2(dt, coutt));
            }
            else
            {
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[]}");
            }
            return;
        }
        //8.咨询检索grid13，条件："a.id = " + idNew
        if (action == "zixunSelect")
        {//api/zixunApi.ashx?action=zixunSelect&idEdit=14&openid=SW05VWJqTXRNRWw2WmxaTVZVUmpURmRXUmw4ek5EQm9VVm80Vnc9PQ==
            try
            {
                idNew = int.Parse(context.Request.Params["idEdit"]);
                string sqlWhere = "";
                if (idNew != 0)
                {
                    sqlWhere = sqlWhere + " and a.id = " + idNew + "";
                }
                else
                {
                    context.Response.Write("false");
                    return;
                }
                string sqlSelect = " select a.*,b.sName from grid13 a LEFT JOIN grid00 b ON a.xId=b.xId where 1=1  " + sqlWhere + "";

                DataTable dt = bc.ReadTable(sqlSelect);
                if (dt.Rows.Count > 0)
                {
                    PublicCla c2 = new PublicCla();
                    context.Response.Write(c2.CreateJsonParameters2(dt, coutt));
                }
                else
                {
                    context.Response.Write("{\"total\":" + coutt + ", \"rows\":[]}");
                }
            }
            catch
            {
                coutt = -1;
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"发生了未知错误！\"}]}");
            }
            return;
        }
        //9.咨询修改grid13，条件："a.id = " + idNew
        if (action == "zixunEdit")
        {//api/zixunApi.ashx?action=zixunEdit&idEdit=14&name=石家庄钢贸公司&leixing=碰到的咨询&mudi=3334c34&jieguo=未解决&openid=SW05VWJqTXRNRWw2WmxaTVZVUmpURmRXUmw4ek5EQm9VVm80Vnc9PQ==
            try
            {
                idNew = int.Parse(context.Request.Params["idEdit"]);
                string num = "";

                string name = context.Request.Params["name"];
                string leixing = context.Request.Params["leixing"];
                string Neirong = context.Request.Params["Neirong"];
                string Neirong2 = context.Request.Params["Neirong2"];
                string mudi = context.Request.Params["mudi"];
                string jieguo = context.Request.Params["jieguo"];
                
                shijian = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                shijian2 = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                sqlUpdate = "update grid13 set  num='" + num + "', name='" + name + "', leixing='" + leixing + "',Neirong='" + Neirong + "',Neirong2='" + Neirong2 + "', mudi='" + mudi + "', jieguo='" + jieguo + "', shijian2='" + shijian2 + "' where id=" + idNew;
                bc.execsql(sqlUpdate);
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"成功进行了保存操作！\"}]}");
            }
            catch
            {
                //context.Response.Write("false");
                coutt = -1;
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"发生了未知错误！\"}]}");
            }
            return;
        }
        //10.咨询新增grid13，idNew = DA.Value_S_AutoidNumber("grid13")
        if (action == "zixunNew")
        {//api/zixunApi.ashx?action=zixunNew&name=石家庄钢贸公司&leixing=碰到的咨询&mudi=3334c34&Neirong=a&Neirong2=b&jieguo=未解决&openid=SW05VWJqTXRNRWw2WmxaTVZVUmpURmRXUmw4ek5EQm9VVm80Vnc9PQ==
            string sqlAll = "";
            try
            {
                idNew = DA.Value_S_AutoidNumber("grid13");
                string num = "";
                string name = context.Request.Params["name"];
                string leixing = context.Request.Params["leixing"];
                string Neirong = context.Request.Params["Neirong"];
                string Neirong2 = context.Request.Params["Neirong2"];
                string mudi = context.Request.Params["mudi"];
                string jieguo = context.Request.Params["jieguo"];
                int xId = 1;
                int tId = 1;
                
                int aId = intId;
                shijian = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                shijian2 = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                string sqladd = "insert into grid13(id,num,name,leixing,Neirong,Neirong2,mudi,jieguo,aId,xId,tId,shijian,shijian2) ";
                sqladd = sqladd + "values(" + idNew + ",'" + num + "','" + name + "','" + leixing + "','" + Neirong + "','" + Neirong2 + "','" + mudi + "','" + jieguo + "'," + aId + "," + xId + "," + tId + ",'" + shijian + "','" + shijian2 + "')";
                sqlAll = sqladd;
                bc.execsql(sqlAll);
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"成功进行了新增操作！\"}]}");
            }
            catch(Exception ex)
            {
                coutt = -1;
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"发生了未知错误！" + sqlAll + "\"}]}");
                //context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"发生了未知错误！" + "\"}]}");
            }
            return;
        }
        //21.问题回复新增grid17，idNew = DA.Value_S_AutoidNumber("grid17")
        if (action == "zixunNew2")
        {//api/tousuApi.ashx?action=jianyiNew2&name=石家庄钢贸公司&leixing=碰到的投诉&Neirong=3334c34&Neirong2=未解决&openid=SW05VWJqTXRNRWw2WmxaTVZVUmpURmRXUmw4ek5EQm9VVm80Vnc9PQ==
            string sqlAll = "";
            try
            {
                idNew = DA.Value_S_AutoidNumber("grid17");
                string num = context.Request.Params["idEdit"];
                string name = context.Request.Params["name"];
                string leixing = context.Request.Params["leixing"];
                string Neirong = context.Request.Params["Neirong"];
                string Neirong2 = context.Request.Params["Neirong2"];                
                string huifu = context.Request.Params["huifu"];
                string huifu2 = context.Request.Params["huifu2"];
                int tId = 1;

                int aId = intId;
                shijian = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                shijian2 = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                name = "grid13";
                string sqladd = "insert into grid17(id,num,name,leixing,Neirong,Neirong2,huifu,huifu2,aId,tId,shijian,shijian2) ";
                sqladd = sqladd + "values(" + idNew + ",'" + num + "','" + name + "','" + leixing + "','" + Neirong + "','" + Neirong2 + "','" + huifu + "','" + huifu2 + "'," + aId + "," + tId + ",'" + shijian + "','" + shijian2 + "')";
                sqlAll = sqladd;
                bc.execsql(sqlAll);
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"成功进行了回复操作！\"}]}");
            }
            catch (Exception ex)
            {
                coutt = -1;
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"发生了未知错误！" + ex.Message + sqlAll + "\"}]}");
            }
            return;
        }
        //22.问题回复列表grid17，条件："a.id = " + idNew
        if (action == "zixunSelect2")
        {//api/custApi.ashx?action=wentiSelect2&idEdit=36&openid=SW05VWJqTXRNRWw2WmxaTVZVUmpURmRXUmw4ek5EQm9VVm80Vnc9PQ==
            try
            {
                idNew = int.Parse(context.Request.Params["idEdit"]);
                string sqlWhere = "";
                if (idNew != 0)
                {
                    sqlWhere = sqlWhere + " and a.name='grid13'  and a.num = " + idNew + "";
                }
                else
                {
                    context.Response.Write("false");
                    return;
                }
                string sqlSelect = " select a.* from grid17 a where 1=1 and a.name='grid13'  " + sqlWhere + "";

                DataTable dt = bc.ReadTable(sqlSelect);
                if (dt.Rows.Count > 0)
                {
                    PublicCla c2 = new PublicCla();
                    context.Response.Write(c2.CreateJsonParameters3(dt, coutt));
                }
                else
                {
                    context.Response.Write("{\"total\":" + coutt + ", \"rows\":[]}");
                }
            }
            catch
            {
                coutt = -1;
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"发生了未知错误！\"}]}");
            }
            return;
        }
        //23.问题修改grid10，是否解决，条件："a.id = " + idNew
        if (action == "zixunEdit2")
        {//api/custApi.ashx?action=zixunEdit2&idEdit=14&name=石家庄钢贸公司&leixing=碰到的问题&mudi=3334c34&jieguo=未解决&openid=SW05VWJqTXRNRWw2WmxaTVZVUmpURmRXUmw4ek5EQm9VVm80Vnc9PQ==
            try
            {
                idNew = int.Parse(context.Request.Params["idEdit"]);
                string jieguo = context.Request.Params["jieguo"];

                shijian = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                shijian2 = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                sqlUpdate = "update grid13 set jieguo='" + jieguo + "', shijian2='" + shijian2 + "' where id=" + idNew;
                bc.execsql(sqlUpdate);
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"成功进行了提交结果操作！\"}]}");
            }
            catch
            {
                //context.Response.Write("false");
                coutt = -1;
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"发生了未知错误！\"}]}");
            }
            return;
        }       
        
        

    }
    //不加的话，提示：不实现接口成员“System.Web.IHttpHandler.IsReusable”
    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

    private int getId2(string strId)
    {
        string strId2 = "";
        if (strId.Length > 27)
        {
            strId2 = strId.Substring(3, 24);
        }
        string strAll = " select aId from admininfo where aOpenId like '%" + strId2 + "%'";
        BaseClass bc = new BaseClass();
        DataTable dt = bc.ReadTable(strAll);
        if (dt.Rows.Count > 0)
        {
            return int.Parse(dt.Rows[0]["aId"].ToString());
        }
        else
        {
            return 0;
        }
    }




}