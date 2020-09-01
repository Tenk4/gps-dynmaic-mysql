/*
	- Credit: All good function from SC:RP https://forum.sa-mp.com/showthread.php?t=538107
	- Credit: Leaks666 from https://youtu.be/QkJyJS7IMSU?t=963
	- Credit: sscanf from Y_Less https://github.com/Y-Less/sscanf
	- Credit: easyDialog from Emmet Southclaws https://github.com/Awsomedude/easyDialog
	- Credit: zcmd from zeex https://forum.sa-mp.com/showthread.php?t=91354
	- Credit: mysql from BlueG https://github.com/pBlueG/SA-MP-MySQL
*/
#include <a_samp>
#include <a_mysql>
#include <zcmd>
#include <sscanf2>
#include <easyDialog>

#define		MYSQL_HOST 				"127.0.0.1"
#define		MYSQL_USER 				"root"
#define		MYSQL_PASSWORD 			""
#define		MYSQL_DATABASE 			"gps"

#define     MAX_GPS     50

new MySQL: g_SQL;

enum GPS_DATA {
	gpsID,
	gpsExists,
	gpsName[32],
	Float:gpsPos[3],
	gpsType
};
new gpsData[MAX_GPS][GPS_DATA];

public OnFilterScriptInit()
{
	mysql_log(ERROR | WARNING);
	new MySQLOpt: option_id = mysql_init_options();

	mysql_set_option(option_id, AUTO_RECONNECT, true);

	g_SQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE, option_id);
	if (g_SQL == MYSQL_INVALID_HANDLE || mysql_errno(g_SQL) != 0)
	{
		print("[MySQL]: Connection failed. Server is shutting down.");
		SendRconCommand("exit");
		return 1;
	}

	print("[MySQL]: Connection is successful.");

    mysql_set_charset("tis620");
    
    mysql_tquery(g_SQL, "SELECT * FROM `gps`", "GPS_Load", "");
	return 1;
}

public OnFilterScriptExit()
{
	mysql_close(g_SQL);
	return 1;
}

forward GPS_Load();
public GPS_Load()
{
	static
	    rows;

	cache_get_row_count(rows);

	for (new i = 0; i < rows; i ++) if (i < MAX_GPS)
	{
	    gpsData[i][gpsExists] = true;

	    cache_get_value_name_int(i, "gpsID", gpsData[i][gpsID]);
	    cache_get_value_name(i, "gpsName", gpsData[i][gpsName], 32);
	    cache_get_value_name_float(i, "gpsX", gpsData[i][gpsPos][0]);
	    cache_get_value_name_float(i, "gpsY", gpsData[i][gpsPos][1]);
	    cache_get_value_name_float(i, "gpsZ", gpsData[i][gpsPos][2]);
	    cache_get_value_name_int(i, "gpsType", gpsData[i][gpsType]);
	}
	printf("[SERVER]: %i GPS were loaded from \"%s\" database...", rows, MYSQL_DATABASE);
	return 1;
}

forward OnGPSCreated(gpsid);
public OnGPSCreated(gpsid)
{
	if (gpsid == -1 || !gpsData[gpsid][gpsExists])
	    return 0;

	gpsData[gpsid][gpsID] = cache_insert_id();
	GPS_Save(gpsid);

	return 1;
}

GPS_Delete(gpsid)
{
	if (gpsid != -1 && gpsData[gpsid][gpsExists])
	{
	    static
	        string[64];

		format(string, sizeof(string), "DELETE FROM `gps` WHERE `gpsID` = '%d'", gpsData[gpsid][gpsID]);
		mysql_tquery(g_SQL, string);

		gpsData[gpsid][gpsExists] = false;
		gpsData[gpsid][gpsID] = 0;
	}
	return 1;
}

GPS_Create(type, const gpsname[], Float:x, Float:y, Float:z)
{
	for (new i = 0; i < MAX_GPS; i ++) if (!gpsData[i][gpsExists])
	{
	    gpsData[i][gpsExists] = true;
	    format(gpsData[i][gpsName], 32, gpsname);
	    gpsData[i][gpsPos][0] = x;
	    gpsData[i][gpsPos][1] = y;
	    gpsData[i][gpsPos][2] = z;
	    gpsData[i][gpsType] = type;

	    mysql_tquery(g_SQL, "INSERT INTO `gps` (`gpsID`) VALUES(0)", "OnGPSCreated", "d", i);
		return i;
	}
	return -1;
}

GPS_Save(gpsid)
{
	static
	    query[220];

	mysql_format(g_SQL, query, sizeof(query), "UPDATE `gps` SET `gpsName` = '%e', `gpsX` = '%.4f', `gpsY` = '%.4f', `gpsZ` = '%.4f', `gpsType` = '%d' WHERE `gpsID` = '%d'",
		gpsData[gpsid][gpsName],
		gpsData[gpsid][gpsPos][0],
	    gpsData[gpsid][gpsPos][1],
	    gpsData[gpsid][gpsPos][2],
	    gpsData[gpsid][gpsType],
	    gpsData[gpsid][gpsID]
	);
	return mysql_tquery(g_SQL, query);
}

CMD:creategps(playerid, params[])
{
	static
	    id = -1,
		Float:x,
		Float:y,
		Float:z,
		gpsname[32],
		type,
		string[128];

	GetPlayerPos(playerid, x, y, z);

	if (sscanf(params, "ds[32]", type, gpsname))
	{
	    SendClientMessage(playerid, -1, "/creategps [ÃÙ»áºº GPS] [ª×èÍÊ¶Ò¹·Õè]");
	    SendClientMessage(playerid, -1, "1. Ê¶Ò¹·Õè·ÑèÇä» 2. §Ò¹¶Ù¡¡®ËÁÒÂ 3. §Ò¹¼Ô´¡®ËÁÒÂ");
	    return 1;
	}
	if (type < 1 || type > 3)
		return SendClientMessage(playerid, -1, "ÃÙ»áºº¢Í§ GPS µéÍ§äÁèµèÓ¡ÇèÒ 1 áÅÐäÁèà¡Ô¹ 3 à·èÒ¹Ñé¹");

	id = GPS_Create(type, gpsname, x, y, z);

	if (id == -1)
	    return SendClientMessage(playerid, -1, "¤ÇÒÁ¨Ø¢Í§ GPS ã¹°Ò¹¢éÍÁÙÅàµçÁáÅéÇ äÁèÊÒÁÒÃ¶ÊÃéÒ§ä´éÍÕ¡ (µÔ´µèÍ¼Ùé¾Ñ²¹Ò)");

	format(string, sizeof(string), "¤Ø³ä´éÊÃéÒ§ GPS ¢Öé¹ÁÒãËÁè ÃÙ»áºº GPS: %d, ª×èÍÊ¶Ò¹·Õè: %s, äÍ´Õ: %d", type, gpsname, id);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:deletegps(playerid, params[])
{
	static
	    id = 0,
		string[64];

	if (sscanf(params, "d", id))
	    return SendClientMessage(playerid, -1, "/deletegps [äÍ´Õ]");

	if ((id < 0 || id >= MAX_GPS) || !gpsData[id][gpsExists])
	    return SendClientMessage(playerid, -1, "äÁèÁÕäÍ´Õ GPS ¹ÕéÍÂÙèã¹°Ò¹¢éÍÁÙÅ");

	GPS_Delete(id);
	format(string, sizeof(string), "¤Ø³ä´éÅº GPS äÍ´Õ %d ÍÍ¡ÊÓàÃç¨", id);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:gps(playerid, params[])
{
	Dialog_Show(playerid, DIALOG_GPS, DIALOG_STYLE_LIST, "[ÃÒÂ¡ÒÃ GPS]", "Ê¶Ò¹·Õè·ÑèÇä»\n§Ò¹¶Ù¡¡®ËÁÒÂ\n§Ò¹¼Ô´¡®ËÁÒÂ", "àÅ×Í¡", "»Ô´");
	return 1;
}

Dialog:DIALOG_GPS(playerid, response, listitem, inputtext[])
{
	if (response)
	{
		switch(listitem)
		{
		    case 0:
		    {
				new
				    count,
				    var[32],
					string[512],
					string2[512];

				for (new i = 0; i != MAX_GPS; i ++) if (gpsData[i][gpsExists])
				{
				    if(gpsData[i][gpsType] == 1)
				    {
						format(string, sizeof(string), "%s\n", gpsData[i][gpsName]);
						strcat(string2, string);
						format(var, sizeof(var), "GPSID%d", count);
						SetPVarInt(playerid, var, i);
						count++;
					}
				}
				if (!count)
				{
					SendClientMessage(playerid, -1, "à«ÔÃì¿àÇÍÃìÂÑ§äÁèä´éà¾ÔèÁ GPS");
					return 1;
				}
				format(string, sizeof(string), "%s", string2);
				Dialog_Show(playerid, DIALOG_GPSPICK, DIALOG_STYLE_LIST, "[Ê¶Ò¹·Õè·ÑèÇä»]", string, "àÅ×Í¡", "»Ô´");
		    }
		    case 1:
		    {
				new
				    count,
				    var[32],
					string[512],
					string2[512];

				for (new i = 0; i != MAX_GPS; i ++) if (gpsData[i][gpsExists])
				{
				    if(gpsData[i][gpsType] == 2)
				    {
						format(string, sizeof(string), "%s\n", gpsData[i][gpsName]);
						strcat(string2, string);
						format(var, sizeof(var), "GPSID%d", count);
						SetPVarInt(playerid, var, i);
						count++;
					}
				}
				if (!count)
				{
					SendClientMessage(playerid, -1, "à«ÔÃì¿àÇÍÃìÂÑ§äÁèä´éà¾ÔèÁ GPS");
					return 1;
				}
				format(string, sizeof(string), "%s", string2);
				Dialog_Show(playerid, DIALOG_GPSPICK, DIALOG_STYLE_LIST, "[§Ò¹¶Ù¡¡®ËÁÒÂ]", string, "àÅ×Í¡", "»Ô´");
		    }
		    case 2:
		    {
				new
				    count,
				    var[32],
					string[512],
					string2[512];

				for (new i = 0; i != MAX_GPS; i ++) if (gpsData[i][gpsExists])
				{
				    if(gpsData[i][gpsType] == 3)
				    {
						format(string, sizeof(string), "%s\n", gpsData[i][gpsName]);
						strcat(string2, string);
						format(var, sizeof(var), "GPSID%d", count);
						SetPVarInt(playerid, var, i);
						count++;
					}
				}
				if (!count)
				{
					SendClientMessage(playerid, -1, "à«ÔÃì¿àÇÍÃìÂÑ§äÁèä´éà¾ÔèÁ GPS");
					return 1;
				}
				format(string, sizeof(string), "%s", string2);
				Dialog_Show(playerid, DIALOG_GPSPICK, DIALOG_STYLE_LIST, "[§Ò¹¼Ô´¡®ËÁÒÂ]", string, "àÅ×Í¡", "»Ô´");
		    }
		}
	}
	return 1;
}

Dialog:DIALOG_GPSPICK(playerid, response, listitem, inputtext[])
{
	if (response)
	{
	    new var[32], string[128];
	    format(var, sizeof(var), "GPSID%d", listitem);
	    new gpsid = GetPVarInt(playerid, var);
		SetPlayerCheckpoint(playerid, gpsData[gpsid][gpsPos][0], gpsData[gpsid][gpsPos][1], gpsData[gpsid][gpsPos][2], 3.0);
		format(string, sizeof(string), "¤Ø³ä´éà»Ô´ÃÐºº GPS ¤é¹ËÒÊ¶Ò¹·Õèª×èÍ %s", gpsData[gpsid][gpsName]);
		SendClientMessage(playerid, -1, string);
	}
	return 1;
}
