import json
import os
import platform
import yaml
import subprocess

currentDirectory = os.getcwd()

host_os = platform.system()
tempfile = '/tmp/vcsa_cfg.json'
homedir = os.getenv('HOME')
print("HOMEDIR is ", homedir)

yaml_file = open(homedir+"/vsphere_config.yaml")
cfg_yaml = yaml.load(yaml_file, Loader=yaml.Loader)

VC_ISO_MOUNT = cfg_yaml["VC_ISO_MOUNT"]
VC_ISO_PATH = cfg_yaml["VC_ISO_PATH"]

if host_os == 'Darwin':
    os.system(f"mkdir {VC_ISO_MOUNT}")
    os.system(f"hdiutil mount {VC_ISO_PATH} -mountroot {VC_ISO_MOUNT}")
    with open(f'{VC_ISO_MOUNT}/VMware VCSA/vcsa-cli-installer/templates/install/embedded_vCSA_on_ESXi.json') as json_file:
        data = json.load(json_file)
elif host_os == 'Linux':
    os.system(f"mkdir {VC_ISO_MOUNT}")
    os.system(f"sudo mount -o loop {VC_ISO_PATH} {VC_ISO_MOUNT}")
    with open(f'{VC_ISO_MOUNT}/vcsa-cli-installer/templates/install/embedded_vCSA_on_ESXi.json') as json_file:
        data = json.load(json_file)
else:
    print(f"Unfortunately {host_os} is not supported")

def deploy_vcsa(data):
    ## vCenter DNS validation
    try:
        for d in cfg_yaml["VC_DNS_SERVERS"]:
            output = subprocess.check_output(['nslookup', cfg_yaml["VC_SYSTEM_NAME"], str(d)], universal_newlines=True)
            res = dict(map(str.strip, sub.split(':', 1)) for sub in output.split('\n') if ':' in sub)
            if cfg_yaml["VC_IP"] != res['Address']:
                raise ValueError("The vCenter FQDN does resolve to the IP " + cfg_yaml["VC_IP"])
    except subprocess.CalledProcessError as err:
        raise ValueError("The vCenter FQDN is not resolving")


    data['new_vcsa']['esxi']['hostname'] = cfg_yaml["VC_ESX_HOST"]
    data['new_vcsa']['esxi']['username'] = cfg_yaml["VC_ESXI_USR"]
    data['new_vcsa']['esxi']['password'] = cfg_yaml["VC_ESXI_PWD"]
    data['new_vcsa']['esxi']['datastore'] = cfg_yaml["VC_ESXI_DATASTORE"]
    data['new_vcsa']['esxi']['deployment_network'] = cfg_yaml["VC_PORTGROUP"]
    data['new_vcsa']['appliance']['thin_disk_mode'] = bool(cfg_yaml["VC_THIN_PROVISION"])
    data['new_vcsa']['appliance']['deployment_option'] = cfg_yaml["VC_DEPLOYMENT_SIZE"]
    data['new_vcsa']['appliance']['name'] = cfg_yaml["VC_NAME"]
    data['new_vcsa']['network']['mode'] = cfg_yaml["VC_NET_MODE"]
    data['new_vcsa']['network']['ip'] = cfg_yaml["VC_IP"]
    data['new_vcsa']['network']['dns_servers'] =  cfg_yaml["VC_DNS_SERVERS"]
    data['new_vcsa']['network']['prefix'] = cfg_yaml["VC_NETMASK"]
    data['new_vcsa']['network']['gateway'] = cfg_yaml["VC_GATEWAY"]
    data['new_vcsa']['network']['system_name'] = cfg_yaml["VC_SYSTEM_NAME"]
    data['new_vcsa']['os']['password'] = cfg_yaml["VC_ROOT_PWD"]
    data['new_vcsa']['os']['ntp_servers'] = cfg_yaml["NTP_SERVER"]
    data['new_vcsa']['os']['ssh_enable'] = bool(cfg_yaml["VC_SSH_ENABLED"])
    data['new_vcsa']['sso']['password'] = cfg_yaml["VC_SSO_PWD"]
    data['new_vcsa']['sso']['domain_name'] = cfg_yaml["VC_SSO_DOMAIN"]
    data['ceip']['settings']['ceip_enabled'] =  bool(cfg_yaml["CEIP_ENABLED"])

    print(data)

    with open (tempfile, 'w') as fp:
        json.dump(data, fp, indent=4)

    ## Deploy
    if host_os == 'Darwin':
        deployvcsa = f'"{VC_ISO_MOUNT}/VMware VCSA/vcsa-cli-installer/mac/vcsa-deploy" \
        install --verbose --accept-eula --acknowledge-ceip \
        --no-ssl-certificate-verification --skip-ovftool-verification \
        {tempfile}'
    elif host_os == 'Linux':
        deployvcsa = f'{VC_ISO_MOUNT}/vcsa-cli-installer/lin64/vcsa-deploy \
        install --verbose --accept-eula --acknowledge-ceip \
        --no-ssl-certificate-verification --skip-ovftool-verification \
        {tempfile}'

    try:
        os.system(deployvcsa)
        # os.remove(tempfile)
        return "SUCCESS"

    except:
        os.remove(tempfile)
        return "FAIL"

    # Unmount
    if host_os == 'Darwin':
        os.system(f"hdiutil umount {VC_ISO_MOUNT}")
    elif host_os == 'Linux':
        os.system(f"sudo umount {VC_ISO_MOUNT}")

def main():
    deploy_status = deploy_vcsa(data)
    print("VCSA deployment status is ", deploy_status)

# Start program if run standalone
if __name__ == '__main__':
    main()
