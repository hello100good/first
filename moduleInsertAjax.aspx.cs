
    using DBUtility;
    using System;
    using System.Web.UI;

public partial class moduleInsertAjax : Page
    {
        private BaseClass bc = new BaseClass();

        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                string lname = base.Server.UrlDecode(base.Request.QueryString["lname"].ToString());
                string lRemark = base.Server.UrlDecode(base.Request.QueryString["lRemark"].ToString());
                string lVersion = base.Server.UrlDecode(base.Request.QueryString["lVersion"].ToString());
                string strnum = "l" + DateTime.Now.ToString("yyMMddHHmmss");
                string sqladd = "insert into module(lNum,lname,lRemark,lStates)";
                string name3 = sqladd;
                sqladd = name3 + "values('" + strnum + "','" + lname + "','" + lRemark + "','" + lVersion + "')";
                this.bc.execsql(sqladd);
                base.Response.Write(strnum);
            }
            catch
            {
                base.Response.Write("false");
            }
        }
    }


