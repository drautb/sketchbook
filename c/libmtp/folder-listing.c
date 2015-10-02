/**
 * Simple C program to connect to an MTP device and list the folders that it
 * contains.
 *
 * Compile on OS X:
 *
 * gcc -o folder-listing `pkg-config --cflags --libs libmtp` folder-listing.c
 *
 */

#include <libmtp.h>
#include <stdlib.h>

LIBMTP_mtpdevice_t *device;
LIBMTP_folder_t *folders;

void dump_folder_list(LIBMTP_folder_t *folderlist, int level) {
  int i;
  if(folderlist==NULL) {
    return;
  }

  printf("%u\t", folderlist->folder_id);
  for(i=0;i<level;i++) printf("  ");

  printf("%s\n", folderlist->name);

  dump_folder_list(folderlist->child, level+1);
  dump_folder_list(folderlist->sibling, level);
}

int main(int argc, char* argv[]) {

  printf("Initializing LIBMTP...\n");
  LIBMTP_Init();

  device = LIBMTP_Get_First_Device();
  if (device == NULL) {
    printf("No devices.\n");
    return 0;
  }

  folders = LIBMTP_Get_Folder_List(device);

  dump_folder_list(folders, 0);

  LIBMTP_destroy_folder_t(folders);

  LIBMTP_Release_Device(device);
}
