#include "substrate.h"
#include <string>
#include <cstdio>
#include <chrono>
#include <memory>
#include <vector>
#include <mach-o/dyld.h>
#include <stdint.h>
#include <cstdlib>
#include <sys/mman.h>
#include <sys/stat.h>
#include <random>
#include <cstdint>
#include <unordered_map>
#include <map>
#include <functional>
#include <cmath>
#include <chrono>
#include <libkern/OSCacheControl.h>
#include <cstddef>
#include <tuple>
#include <mach/mach.h>
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/reloc.h>

#include <dlfcn.h>

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

struct BlockSource;
struct TextureUVCoordinateSet;
struct PlayerInventoryProxy;
struct LevelRenderer;

struct Item {
	uintptr_t** vtable; // 0
	uint8_t maxStackSize; // 8
	int idk; // 12
	std::string atlas; // 16
	int frameCount; // 40
	bool animated; // 44
	short itemId; // 46
	std::string name; // 48
	std::string idk3; // 72
	bool isMirrored; // 96
	short maxDamage; // 98
	bool isGlint; // 100
	bool renderAsTool; // 101
	bool stackedByData; // 102
	uint8_t properties; // 103
	int maxUseDuration; // 104
	bool explodeable; // 108
	bool shouldDespawn; // 109
	bool idk4; // 110
	uint8_t useAnimation; // 111
	int creativeCategory; // 112
	float idk5; // 116
	float idk6; // 120
	char buffer[12]; // 124
	TextureUVCoordinateSet* icon; // 136
	char filler[100];
};

struct LevelData
{
	char filler[48]; // 0
	std::string levelName; // 48
	char filler2[44]; // 72
	int time; // 116
	char filler3[144]; // 120
	int gameType; // 264
	int difficulty; // 268
};

struct Level
{
	char filler[160]; // 0
	LevelData data; // 160
};

struct Entity
{
	char filler[64];
	Level* level; // 64
	char filler2[104]; // 72
	BlockSource* region; // 176
};

struct Player :public Entity
{
	char filler[4400]; // 184
	PlayerInventoryProxy* inventory; // 4584
};

struct ItemInstance {
	uint8_t count;
	uint16_t aux;
	uintptr_t* tag;
	Item* item;
	uintptr_t* block;
};


struct Vec3 {
	float x, y, z;
};

enum class EntityLocation : int {
	IDK = 0
};

static Item** Item$mItems;

LevelRenderer* renderer = NULL;

static uintptr_t** VTAppPlatformiOS;

Level*(*Entity$getLevel)(Entity*);
BlockSource&(*Entity$getRegion)(Entity*);

void (*LevelRenderer$playSound)(LevelRenderer*, Entity const&, EntityLocation, std::string const&, float, float);

void (*_LevelRenderer$tick)(LevelRenderer*);
void LevelRenderer$tick(LevelRenderer* _renderer) {

	renderer = _renderer;

	_LevelRenderer$tick(_renderer);
}

bool (*_Item$useOn)(Item*, ItemInstance*, Player*, int, int, int, signed char, float, float, float);
bool Item$useOn(Item* self, ItemInstance* inst, Player* player, int x, int y , int z, signed char side, float xx, float yy, float zz) {
	if(self == Item$mItems[280]) {
		LevelRenderer$playSound(renderer, *player, EntityLocation::IDK, "note.pecharge", 20, 2);
	}

	return _Item$useOn(self, inst, player, x, y, z, side, xx, yy, zz);
}

void*(*_FMOD$System$createStream)(uintptr_t*, const char*, unsigned int, void*, void**);
void* FMOD$System$createStream(uintptr_t* self, const char* path, unsigned int unk1, void* unk2, void** unk3) {
        if (strstr(path, "note/pecharge.ogg"))
                path = "/Library/Application Support/addsound/sounds/pecharge.ogg";

    NSLog(@"FMOD$System$createStream - path:%s", path);
    return _FMOD$System$createStream(self, path, unk1, unk2, unk3);
}

static std::string (*_AppPlatformiOS$readAssetFile)(uintptr_t*, std::string const&);
static std::string AppPlatformiOS$readAssetFile(uintptr_t* self, std::string const& str) {

    if (strstr(str.c_str(), "minecraftpe.app/data/sounds/note/pecharge.ogg")) {
        NSLog(@"AppPlatformiOS$readAssetFile - working!");
        return _AppPlatformiOS$readAssetFile(self, "/Library/Application Support/addsound/sounds/pecharge.ogg");
    }

    std::string content = _AppPlatformiOS$readAssetFile(self, str);
    if (strstr(str.c_str(), "minecraftpe.app/data/sounds/sounds.json")) {
        NSString *jsonString = [NSString stringWithUTF8String:content.c_str()];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonError;
        NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&jsonError];

        [jsonDict setObject:@{
            @"category": @"record",
            @"sounds": @[
                @{ @"name": @"note/pecharge", @"stream": @YES }
            ]
        } forKey:@"note.pecharge"];
       
        jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&jsonError];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        content = std::string([jsonString UTF8String]);
    }
    return content;
}

%ctor {
	VTAppPlatformiOS = (uintptr_t**)(0x1011695f0 + _dyld_get_image_vmaddr_slide(0));
	_AppPlatformiOS$readAssetFile = (std::string(*)(uintptr_t*, std::string const&)) VTAppPlatformiOS[58];
	VTAppPlatformiOS[58] = (uintptr_t*)&AppPlatformiOS$readAssetFile;

	Item$mItems = (Item**)(0x1012ae238 + _dyld_get_image_vmaddr_slide(0));

	Entity$getLevel = (Level*(*)(Entity*))(0x100657df8 + _dyld_get_image_vmaddr_slide(0));
	Entity$getRegion = (BlockSource&(*)(Entity*))(0x100658034 + _dyld_get_image_vmaddr_slide(0));

	LevelRenderer$playSound = (void(*)(LevelRenderer*, Entity const&, EntityLocation, std::string const&, float, float))(0x10040249c + _dyld_get_image_vmaddr_slide(0));

	MSHookFunction((void*)(0x100746be0 + _dyld_get_image_vmaddr_slide(0)), (void*)&Item$useOn, (void**)&_Item$useOn);
	MSHookFunction((void*)(0x1003f9f90 + _dyld_get_image_vmaddr_slide(0)), (void*)&LevelRenderer$tick, (void**)&_LevelRenderer$tick);

	MSHookFunction((void*)(0x100D3552C + _dyld_get_image_vmaddr_slide(0)), (void*)&FMOD$System$createStream, (void**)&_FMOD$System$createStream);
}