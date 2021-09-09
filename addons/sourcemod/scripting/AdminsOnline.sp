/*
TODO

Online admins plugin:

add flag for owners, admins, vips
create cmd to hide admins from the online list 



*/


#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Levi2288"
#define PLUGIN_VERSION "1.00"
#define ChatTag "[Admins]"

#define OwnerTag "[Owner]"
#define AdminTag "[Admin]"
#define ModTag "[Mod]"
#define VipTag "[Vip]"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
//#include <sdkhooks>

#pragma newdecls required

ConVar sm_hideme_flag, sm_adminlist_enable, sm_adminlist_cmds, sm_include_vips, sm_owner_flag, sm_admin_flag, sm_vip_flag, sm_mod_flag;
char g_sOwnerFlag[32], g_sAdminFlag[32], g_sVipFlag[32], g_sHideMeFlag[32], g_sModFlag[32];

Handle Cookie_Hideme = INVALID_HANDLE;
bool g_bHideMeUser[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Online Admins Plugin",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "https://github.com/Bufika2288"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_hideme", Hideme);
	
	
	sm_adminlist_enable = CreateConVar("sm_adminlist_enable", "1","Enable the plugin");
	
	sm_adminlist_cmds = CreateConVar("sm_adminlist_cmds", "admins","Adminlist Command - You can set here custom commands to open the main menu");
	
	sm_include_vips = CreateConVar("sm_include_vips", "1", "Include vips into the admin list?");
	
	sm_hideme_flag = CreateConVar("sm_hideme_flag", "b", "Flag to use the hide function cmd (Empty flag = everyone can use it");
	
	
	sm_owner_flag = CreateConVar("sm_owner_flag", "z", "Owner Admin flag (Empty flag = disable)");
	
	sm_admin_flag = CreateConVar("sm_admin_flag", "b", "Generic Admin flag (Empty flag = disable)");
	
	sm_mod_flag = CreateConVar("sm_mod_flag", "", "Vip Admin flag (Empty flag = disable)");
	
	sm_vip_flag = CreateConVar("sm_vip_flag", "o", "Vip Admin flag (Empty flag = disable)");
	
	Cookie_Hideme = RegClientCookie("OnlineAdmins_hideme", "Hideme for online admins", CookieAccess_Private);
	
	
	AutoExecConfig(true, "levi2288_online_admins");
	
	for (int i = MaxClients; i > 0; --i)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		
		if (AreClientCookiesCached(i))
		{
		    OnClientCookiesCached(i);
		}
	}
}

public void OnClientCookiesCached( int client )
{
	char strCookie[8];

	GetClientCookie(client, Cookie_Hideme, strCookie, sizeof(strCookie));
	g_bHideMeUser[client] = (strCookie[0] != '\0' && StringToInt(strCookie)); 	
	
}

public Action Hideme(int client, int args)
{
	if(CheckAdminFlags(client, ReadFlagString(g_sHideMeFlag)))
	{
		g_bHideMeUser[client] = !g_bHideMeUser[client];
		SetCookie(client, Cookie_Hideme, g_bHideMeUser[client]);
		if(g_bHideMeUser[client])
		{
			PrintToChat(client, "%s HideMe activated", ChatTag);
	
		}
		else
		{
			PrintToChat(client, "%s  HideMe deactivated", ChatTag);
		}
	}
	else
	{
		PrintToChat(client, "%s You dont have access to use this command", ChatTag);

	}
}


public void OnConfigsExecuted()
{

	GetConVarString(sm_owner_flag, g_sOwnerFlag, sizeof(g_sOwnerFlag));
	GetConVarString(sm_admin_flag, g_sAdminFlag, sizeof(g_sAdminFlag));
	GetConVarString(sm_mod_flag, g_sModFlag, sizeof(g_sModFlag));
	GetConVarString(sm_vip_flag, g_sVipFlag, sizeof(g_sVipFlag));
	
	GetConVarString(sm_hideme_flag, g_sHideMeFlag, sizeof(g_sHideMeFlag));
	
	int iCount = 0;
	char sCommands[128];
	char sCommandsL[12][32];
	char sCommand[32];
	
	if(sm_adminlist_enable)
	{
		sm_adminlist_cmds.GetString(sCommands, sizeof(sCommands));
		ReplaceString(sCommands, sizeof(sCommands), " ", "");
		
		iCount = ExplodeString(sCommands, ",", sCommandsL, sizeof(sCommandsL), sizeof(sCommandsL[]));
	
		for (int i = 0; i < iCount; i++)
		{
			Format(sCommand, sizeof(sCommand), "sm_%s", sCommandsL[i]);
			
			if (!CommandExists(sCommand))
			{
				RegConsoleCmd(sCommand, ADMNListMain, "Open the Adminlist menu");
			}
		}
	}
}

public Action ADMNListMain(int client, int args)
{
	char Name[MAX_NAME_LENGTH];
	char buffer[128];
	Handle menu = CreateMenu(admin_menuhandler);
	SetMenuTitle(menu, "★ Online Admins ★");
	AddMenuItem(menu, "spacer", "spacer", ITEMDRAW_SPACER);
	bool bMenuIsFilled = false;
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(!g_bHideMeUser[i])
			{
				
				if(IsClientOwner(i))
				{
					GetClientName(i, Name, sizeof(Name));
					Format(buffer, sizeof(buffer), "%s %s", OwnerTag, Name);
					AddMenuItem(menu, "Owners", buffer, ITEMDRAW_DISABLED);
					bMenuIsFilled = true;
				}
				else if(IsClientAdmin(i))
				{
					GetClientName(i, Name, sizeof(Name));
					Format(buffer, sizeof(buffer), "%s %s", AdminTag, Name);
					AddMenuItem(menu, "Admins", buffer, ITEMDRAW_DISABLED); 
					bMenuIsFilled = true;
				}
				else if(IsClientMod(i))
				{
					GetClientName(i, Name, sizeof(Name));
					Format(buffer, sizeof(buffer), "[Mod] %s", Name);
					AddMenuItem(menu, "Mods", buffer, ITEMDRAW_DISABLED); 
					bMenuIsFilled = true;
				}
				
				if(sm_include_vips)
				{
					if(IsClientVip(i) && !IsClientAdmin(i) && !IsClientOwner(i))
					{
						GetClientName(i, Name, sizeof(Name));
						Format(buffer, sizeof(buffer), "[Vip] %s", Name);
						AddMenuItem(menu, "Vips", buffer, ITEMDRAW_DISABLED);
						bMenuIsFilled = true;
					}
				}
			}
		}
	}
	if(bMenuIsFilled == false)
	{
		AddMenuItem(menu, "NoOnline", "There is no admins onine :/", ITEMDRAW_DISABLED);
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);

}

public int admin_menuhandler(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
	}
	else if (action == MenuAction_Cancel)
	{
	}
	else if (action == MenuAction_End)
	{
	}
}


public bool IsClientOwner(int client)
{
	if(StrEqual(g_sOwnerFlag, ""))
	{
		return false;
	}
	else
	{
		if(CheckAdminFlags(client, ReadFlagString(g_sOwnerFlag)))
		{
			return true;
		}
		else 
		{
			return false;
		}

	}
}

public bool IsClientAdmin(int client)
{
	if(StrEqual(g_sAdminFlag, ""))
	{
		return false;
	}
	
	else
	{
		if(CheckAdminFlags(client, ReadFlagString(g_sAdminFlag)))
		{
			return true;
		}
		else 
		{
			return false;
		}

	}
}

public bool IsClientMod(int client)
{
	if(StrEqual(g_sModFlag, ""))
	{
		return false;
	}
	else
	{
		if(CheckAdminFlags(client, ReadFlagString(g_sModFlag)))
		{
			return true;
		}
		else 
		{
			return false;
		}
	}

}

public bool IsClientVip(int client)
{
	if(StrEqual(g_sModFlag, ""))
	{
		return false;
	}
	else
	{
		if(CheckAdminFlags(client, ReadFlagString(g_sVipFlag)))
		{
			return true;
		}
		else 
		{
			return false;
		}
	}

}

stock void SetCookie(int client, Handle hCookie, int n)
{
	char strCookie[64];
	
	IntToString(n, strCookie, sizeof(strCookie));

	SetClientCookie(client, hCookie, strCookie);
}


bool CheckAdminFlags(int client, int iFlag)
{
	int iUserFlags = GetUserFlagBits(client);
	return (iUserFlags & ADMFLAG_ROOT || (iUserFlags & iFlag) == iFlag);
}