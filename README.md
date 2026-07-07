## INOI A75 (_A750_)
## Recovery device tree (TWRP, PBRP, OrangeFox, SHRP)

## Device specifications

Device                  | INOI A75
-----------------------:|:-----------------------------------------
SoC                     | Mediatek Helio G99 (6 nm)
CPU                     | Octa-core (2x2.2 GHz Cortex-A76 & 6x2.0 GHz Cortex-A55)
GPU                     | Mali-G57 MC2
Memory                  | 6/8 GB RAM
Storage                 | 256/512 GB (UFS 2.2)
MicroSD                 | microSDXC (dedicated slot)
Shipped Android Version | 14.0
Battery                 | Non-removable 5000 mAh
Display                 | 1080 x 2460 pixels, 6.8 inches, 120hz
Camera                  | 50 MP AI Rear Camera + 2MP Macro lens; 24 MP (front)

## Device picture

![ INOI A75 ](https://inoi.com/wp-content/uploads/2025/02/inoi-purple-power-smartphone-A75-elegance-france.webp "INOI A75")

## Features

Works:

- [X] ADB
- [X] Decryption
- [X] Display
- [X] Fasbootd
- [X] Flashing
- [X] MTP
- [X] Sideload
- [X] USB OTG
- [X] Vibrator
- [ ] DT2W

## Building
### TWRP, PBRP
_Lunch_ command :

```
lunch twrp_INOI_A75-eng && mka vendorbootimage
```

### SHRP, OrangeFox
_Lunch_ command :

```
lunch twrp_INOI_A75-eng && mka adbd vendorbootimage
```
