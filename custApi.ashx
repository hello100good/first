<%@ WebHandler Language="C#" Class="custApi" %>

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
using System.Text.RegularExpressions;

public class returnOpenid2
{
    public string session_key;
    public string expires_in;
    public string openid;
}
//grid10问题表
public class custApi : IHttpHandler
{
    string openid = "";
    string session_key = "";
    public void ProcessRequest(HttpContext context)
    {
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
        string getReturn = "";
        int idNew = 0;
        int intId = 0;
        string shijian = "";
        string shijian2 = "";
        string sqlUpdate = "";
        string sqlRecord = "";
        DataAction DA = new DataAction();
        int coutt = 0;

        //0.获取小程序微信登录的openId  appid: appid, secret: secret, js_code: userInfo.code
        if (action == "getOpenId")
        {//api/userApi.ashx?action=getOpenId&js_code=011UY6Nu1IrS0a08EKMu1091Nu1UY6Nb
            string appid = "wx78792fca07b1c81a";
            string secret = "90a79f4834609e78f07c336cba50206b";
            string grant_type = "authorization_code";
            string js_code = context.Request.Params["js_code"];

            getReturn = GetAccessToken(appid, secret, js_code, grant_type);
            //先判断这个账号5分钟之内是否登陆过，如果没有，则插入登陆记录

            context.Response.Write(getReturn);

            //string shijian2 = DateTime.Now.ToString("yyyy-mm-dd") + " " + DateTime.Now.Hour.ToString("hh") + ":" + dtMinute2 + ":" + DateTime.Now.Second.ToString("ss");

            //判断openId有无，无：自动创建微信用户；有：获取用户信息aId=intId；统一保存登录信息

            if (openid != "")
            {
                string sqlUserId = "select * from admininfo  where aOpenId='" + openid + "'";
                DataTable dtUser = bc.ReadTable(sqlUserId);
                if (dtUser.Rows.Count == 0)
                {
                    string aIfuser = "ZZ";
                    string strNum = "C0|C1|C2|C101|C102|C103|C104|C105|C201|C203|C204|C205|";
                    string aRnum = "10001";
                    string aPwd = DESEncrypt.Encrypt("123");
                    idNew = DA.Value_S_AutoidNumber("admininfo");
                    shijian = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                    //sqlUpdate = "insert into admininfo(aId,aOpenId) values(" + idNew + ", '" + openid + "') ";
                    sqlUpdate = "insert into admininfo(aId,aOpenId,shijian,aIfuser,aFast,aRnum,aPwd,aLogins) values(" + idNew + ", '" + openid + "','" + shijian + "','" + aIfuser + "','" + strNum + "','" + aRnum + "','" + aPwd + "',1) ";
                    bc.execsql(sqlUpdate);
                    intId = idNew;
                }
                else
                {
                    shijian2 = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                    intId = getId2(openid);
                    sqlUpdate = "update admininfo set  aLogins=ISNULL(aLogins,0)+1,  shijian2='" + shijian2 + "' where aId=" + intId;
                    bc.execsql(sqlUpdate);
                }
                //先判断这个账号5分钟之内是否登陆过，如果是
                shijian = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                shijian2 = DateTime.Now.AddMinutes(-10).ToString("yyyy-MM-dd HH:mm:ss"); //加n分                  
                sqlRecord = "select * from record  where openId='" + openid + "' and shijian<'" + shijian + "' and shijian>'" + shijian2 + "'";
                DataTable dtRecord = bc.ReadTable(sqlRecord);
                if (dtRecord.Rows.Count == 0)
                {
                    idNew = DA.Value_S_AutoidNumber("record");
                    sqlUpdate = "insert into record(rId,aId,openId,shijian) values(" + idNew + ",'" + intId + "','" + openid + "','" + shijian + "') ";
                    bc.execsql(sqlUpdate);
                }
                else
                {
                    //idNew = DA.Value_S_AutoidNumber("record");
                    //sqlUpdate = "insert into record(rId,aId,openId,shijian) values(" + idNew + ",'" + idNew + "','" + openid + "','" + shijian + "') ";
                    //bc.execsql(sqlUpdate);
                }
            }
            return;
        }

        
        
        
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
        {//api/custApi.ashx?action=userinfo&openid=YjFSdU15MHdTWHBtVmt4VlJHTk1WMVpHWHpNME1HaFJXamhYWnc9PQ==
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
        //2.修改完善用户信息，条件："a.aId = " + intId
        if (action == "userEdit")
        {//api/custApi.ashx?action=userEdit&openid=YjFSdU15MHdTWHBtVmt4VlJHTk1WMVpHWHpNME1HaFJXamhYWnc9PQ==&aNum=1&aWeixin=2
            string aNum = context.Request.Params["aNum"];
            string aWeixin = context.Request.Params["aWeixin"];
            string aName = context.Request.Params["aName"];
            shijian2 = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            sqlUpdate = "update admininfo set  aNum='" + aNum + "',  aWeixin='" + aWeixin + "',  aName='" + aName + "',shijian2='" + shijian2 + "' where aId=" + intId;
            bc.execsql(sqlUpdate);
            context.Response.Write("true");
            return;
        }

        if (action == "userPhone")
        {
            string strPhone = context.Request.Params["aNum"];
            Regex dReg = new Regex("[0-9]{11,11}");
            if (dReg.IsMatch(strPhone.Trim()))
            {
                newRandom newRandom1 = new newRandom();
                int number;
                char code;
                string checkCode = String.Empty;
                System.Random random = new Random();
                for (int i = 0; i < 4; i++)
                {
                    number = random.Next();
                    code = (char)('0' + (char)(number % 10));
                    checkCode += code.ToString();
                }
                PublicCla.HZ = checkCode;       //验证码

                // 请根据实际 appid 和 appkey 进行开发，以下只作为演示 sdk 使用
                int sdkappid = 1400019505;
                string appkey = "b9e978bb20a3eb8301aaa76b30cc35a4";
                string strSms = "钢贸云提醒您：你的验证码是{" + checkCode + "}";//带参数
                strSms = "{" + checkCode + "}（普讯合伙人验证码，十分钟内有效）";//带参数

                //"黄总：
                sdkappid = 1400034259;
                appkey = "b1e9a1b97531bec02491fabe0dd8c246";

                SmsSender senderDemo = new SmsSender(sdkappid, appkey);
                //SmsSender senderDemo = new SmsSender(1400022240, "7892efdd3f342848f8e1c60097772f0b"); //黄总-享钢网

                string phoneNumber1 = strPhone;
                string phoneNumber2 = "";
                string phoneNumber3 = "";

                SmsMultiSenderResult multiResult;
                SmsMultiSender multiSender = new SmsMultiSender(sdkappid, appkey);
                List<string> phoneNumbers = new List<string>();
                if (phoneNumber1.Length == 11)
                {
                    phoneNumbers.Add(phoneNumber1);
                }
                if (phoneNumber2.Length == 11)
                {
                    phoneNumbers.Add(phoneNumber2);
                }
                if (phoneNumber3.Length == 11)
                {
                    phoneNumbers.Add(phoneNumber3);
                }

                // 普通群发
                // 下面是 3 个假设的号码
                multiResult = multiSender.Send(0, "86", phoneNumbers, strSms, "", "");
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"valid\":\"" + checkCode + "\"}]}");
                return;
            }
        }
        
        
        //3 获取统计数据 ，条件："a.aId = " + intId grid10问题表，grid14投诉表 ，grid13咨询表，grid13建议表 grid05签到
        if (action == "getCount")
        {//api/custApi.ashx?action=getCount&openid=T2lKdlZHNHpMVEJKZW1aV1RGVkVZMHhYVmtaZk16UXdhRkZhT0E9PQ==
            shijian = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            shijian2 = (int.Parse(shijian.Substring(0, 4)) - 1).ToString() + shijian.Substring(4, 15);
            string sqlwhat = " select '1' as shunxun, COUNT(a.id) as zhi FROM grid10 a where a.aId=" + intId + " and left(a.shijian,10)<'" + shijian + "'";
            sqlwhat = sqlwhat + " union select  '2' as shunxun, COUNT(a.id) as zhi FROM grid13 a where a.aId=" + intId + " and left(a.shijian,10)<'" + shijian + "'";
            sqlwhat = sqlwhat + " union select  '3' as shunxun, COUNT(a.id) as zhi FROM grid14 a where a.aId=" + intId + " and tId=1 and left(a.shijian,10)<'" + shijian + "'";
            sqlwhat = sqlwhat + " union select  '4' as shunxun, COUNT(a.id) as zhi FROM grid14 a where a.aId=" + intId + " and tId=2  and left(a.shijian,10)<'" + shijian + "'";
            sqlwhat = sqlwhat + " order by shunxun  ";

            DataTable dt = bc.ReadTable(sqlwhat);
            coutt = dt.Rows.Count;
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


        //7.问题列表grid10，条件："a.aId = " + intId
        if (action == "wentiAll")
        {//api/custApi.ashx?action=wentiAll&openid=SW05VWJqTXRNRWw2WmxaTVZVUmpURmRXUmw4ek5EQm9VVm80Vnc9PQ==&sousuo=,
            //string sqll = " where 1=1  and a.xId=b.xId  ";
            string sousuo = context.Request.Params["sousuo"];
            string[] sousuo2 = sousuo.Split(new char[] { ',' });
            string name = sousuo2[0];
            string jieguo = sousuo2[1];
            string sqll = " where 1=1    ";
            sqll = sqll + " and a.aId = " + intId ;
            if (name != "")
            {
                sqll = sqll + " and a.name like '%" + name + "%'";
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

            //string sqlwhat1 = " select  a.id,a.num,a.name,a.aId,a.xId,a.leixing,a.mudi,a.jieguo,a.Tianxie,a.shenhe,a.shijian,LEFT(a.shijian,7) as yuefen,b.sName    from  grid10 a,grid00 b    ";
            //string sqlwhat2 = " union select COUNT(a.id),'0','0','0','0','0','0','0','0','0','2050',LEFT(a.shijian,7),'' as yuefen  from  grid10 a,grid00 b  ";
            //string strAll = sqlwhat1 + sqll + sqlwhat2 + sqll + " group by LEFT(a.shijian,7) order by yuefen desc,a.shijian desc  ";

            string sqlwhat1 = " select  a.id,a.num,a.name,a.aId,a.xId,a.leixing,a.mudi,a.jieguo,a.Tianxie,a.shenhe,a.shijian,LEFT(a.shijian,7) as yuefen from  grid10 a    ";
            string sqlwhat2 = " union select COUNT(a.id),'0','0','0','0','0','0','0','0','0','2050',LEFT(a.shijian,7) as yuefen  from  grid10 a  ";
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
        //8.问题检索grid10，条件："a.id = " + idNew
        if (action == "wentiSelect")
        {//api/custApi.ashx?action=wentiSelect&idEdit=30&openid=SW05VWJqTXRNRWw2WmxaTVZVUmpURmRXUmw4ek5EQm9VVm80Vnc9PQ==
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
                string sqlSelect = " select a.*,b.sName from grid10 a LEFT JOIN grid00 b ON a.xId=b.xId where 1=1  " + sqlWhere + "";

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
        //9.问题修改grid10，条件："a.id = " + idNew
        if (action == "wentiEdit")
        {//api/custApi.ashx?action=wentiEdit&idEdit=14&name=石家庄钢贸公司&leixing=碰到的问题&mudi=3334c34&jieguo=未解决&openid=SW05VWJqTXRNRWw2WmxaTVZVUmpURmRXUmw4ek5EQm9VVm80Vnc9PQ==
            try
            {
                idNew = int.Parse(context.Request.Params["idEdit"]);
                string num = "";

                string name = context.Request.Params["name"];
                string leixing = context.Request.Params["leixing"];
                string wenti = context.Request.Params["wenti"];
                string wenti2 = context.Request.Params["wenti2"];
                string mudi = context.Request.Params["mudi"];
                string jieguo = context.Request.Params["jieguo"];
                
                shijian = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                shijian2 = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                sqlUpdate = "update grid10 set  num='" + num + "', name='" + name + "', leixing='" + leixing + "',wenti='" + wenti + "',wenti2='" + wenti2 + "', mudi='" + mudi + "', jieguo='" + jieguo + "', shijian2='" + shijian2 + "' where id=" + idNew;
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
        //10.问题新增grid10，idNew = DA.Value_S_AutoidNumber("grid10")
        if (action == "wentiNew")
        {//api/custApi.ashx?action=wentiNew&name=石家庄钢贸公司&leixing=碰到的咨询&mudi=3334c34&wenti=a&wenti2=b&jieguo=未解决&openid=SW05VWJqTXRNRWw2WmxaTVZVUmpURmRXUmw4ek5EQm9VVm80Vnc9PQ==
            string sqlAll = "";
            try
            {
                idNew = DA.Value_S_AutoidNumber("grid10");
                string num = "";
                
                string name = context.Request.Params["name"];
                string leixing = context.Request.Params["leixing"];
                string wenti = context.Request.Params["wenti"];
                string wenti2 = context.Request.Params["wenti2"];
                string mudi = context.Request.Params["mudi"];
                string jieguo = context.Request.Params["jieguo"];
                int xId = 1;
                
                int aId = intId;
                shijian = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                shijian2 = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                string sqladd = "insert into grid10(id,num,name,leixing,wenti,wenti2,mudi,jieguo,aId,xId,shijian,shijian2) ";
                sqladd = sqladd + "values(" + idNew + ",'" + num + "','" + name + "','" + leixing + "','" + wenti + "','" + wenti2 + "','" + mudi + "','" + jieguo + "'," + aId + "," + xId + ",'" + shijian + "','" + shijian2 + "')";
                sqlAll = sqladd;
                bc.execsql(sqlAll);
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"成功进行了新增操作！\"}]}");
            }
            catch(Exception ex)
            {
                coutt = -1;
                context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"发生了未知错误！" + ex.Message + sqlAll + "\"}]}");
            }
            return;
        }
        //20.问题回复新增grid17，idNew = DA.Value_S_AutoidNumber("grid17")
        if (action == "wentiNew2")
        {//api/custApi.ashx?action=wentiNew2&name=石家庄钢贸公司&leixing=碰到的投诉&Neirong=3334c34&Neirong2=未解决&huifu=a&huifu2=&openid=SW05VWJqTXRNRWw2WmxaTVZVUmpURmRXUmw4ek5EQm9VVm80Vnc9PQ==
            string sqlAll = "";
            try
            {
                idNew = DA.Value_S_AutoidNumber("grid17");
                string num = context.Request.Params["idEdit"];
                string name = context.Request.Params["name"];
                string leixing = context.Request.Params["leixing"];
                string Neirong = context.Request.Params["wenti"];
                string Neirong2 = context.Request.Params["wenti2"];
                string huifu = context.Request.Params["Fangfa"];
                string huifu2 = context.Request.Params["Fangfa2"];
                int tId = 1;

                int aId = intId;
                shijian = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                shijian2 = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                name = "grid10";
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
        //21.问题回复列表grid17，条件："a.id = " + idNew
        if (action == "wentiSelect2")
        {//api/custApi.ashx?action=wentiSelect2&idEdit=36&openid=SW05VWJqTXRNRWw2WmxaTVZVUmpURmRXUmw4ek5EQm9VVm80Vnc9PQ==
            try
            {
                idNew = int.Parse(context.Request.Params["idEdit"]);
                string sqlWhere = "";
                if (idNew != 0)
                {
                    sqlWhere = sqlWhere + " and a.name='grid10'  and a.num = " + idNew + "";
                }
                else
                {
                    context.Response.Write("false");
                    return;
                }
                string sqlSelect = " select a.* from grid17 a where 1=1 and a.name='grid10'  " + sqlWhere + "";

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
        //22.问题修改grid10，是否解决，条件："a.id = " + idNew
        if (action == "wentiEdit2")
        {//api/custApi.ashx?action=wentiEdit2&idEdit=14&name=石家庄钢贸公司&leixing=碰到的问题&mudi=3334c34&jieguo=未解决&openid=SW05VWJqTXRNRWw2WmxaTVZVUmpURmRXUmw4ek5EQm9VVm80Vnc9PQ==
            try
            {
                idNew = int.Parse(context.Request.Params["idEdit"]);
                string jieguo = context.Request.Params["jieguo"];

                shijian = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                shijian2 = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                sqlUpdate = "update grid10 set jieguo='" + jieguo + "', shijian2='" + shijian2 + "' where id=" + idNew;
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
        //11.问题图片上传grid10，idNew = DA.Value_S_AutoidNumber("grid10")
        //if (action == "wentiUpload")
        //{
        //    string sqlAll = "";
        //    try
        //    {
        //        idNew = DA.Value_S_AutoidNumber("grid10");
        //        string num = "";


        //        string name = context.Request.Params["name"];
        //        string leixing = context.Request.Params["leixing"];
        //        string wenti = context.Request.Params["wenti"];
        //        string wenti2 = context.Request.Params["wenti2"];
        //        string mudi = context.Request.Params["mudi"];
        //        string jieguo = context.Request.Params["jieguo"];
        //        int xId = 1;

        //        int aId = intId;
        //        shijian = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        //        shijian2 = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        //        string sqladd = "insert into grid10(id,num,name,leixing,wenti,wenti2,mudi,jieguo,aId,xId,shijian,shijian2) ";
        //        sqladd = sqladd + "values(" + idNew + ",'" + num + "','" + name + "','" + leixing + "','" + wenti + "','" + wenti2 + "','" + mudi + "','" + jieguo + "'," + aId + "," + xId + ",'" + shijian + "','" + shijian2 + "')";
        //        sqlAll = sqladd;
        //        bc.execsql(sqlAll);
        //        context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"成功进行了新增操作！\"}]}");
        //    }
        //    catch (Exception ex)
        //    {
        //        coutt = -1;
        //        context.Response.Write("{\"total\":" + coutt + ", \"rows\":[{ \"tishi\":\"发生了未知错误！" + ex.Message + sqlAll + "\"}]}");
        //    }
        //    return;
        //}
        
        
        
        

    }

    /// <summary>
    /// 获取AccessToken
    /// </summary>
    /// <returns>AccessToken</returns>
    public string GetAccessToken(string appid, string appsecret, string code, string grant_type)
    {
        BaseClass bc = new BaseClass();
        string accessToken = "";

        //"https://api.weixin.qq.com/sns/jscode2session?appid={0}&secret={1}&js_code={2}&grant_type=authorization_code",
        string url = string.Format("https://api.weixin.qq.com/sns/jscode2session?appid={0}&secret={1}&js_code={2}&grant_type={3}", appid, appsecret, code, grant_type);

        HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
        HttpWebResponse response = (HttpWebResponse)request.GetResponse();

        using (Stream resStream = response.GetResponseStream())
        {
            StreamReader reader = new StreamReader(resStream, Encoding.Default);
            accessToken = reader.ReadToEnd();
            resStream.Close();
        }
        PublicCla p = new PublicCla();


        if (accessToken.Length > 99)
        {
            returnOpenid2 user = (returnOpenid2)JsonConvert.DeserializeObject(accessToken, typeof(returnOpenid2));
            openid = user.openid;
            session_key = user.session_key;
        }
        string encText = "{\"thSession\":\"" + p.Encode(accessToken) + "\"}";

        return encText;
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