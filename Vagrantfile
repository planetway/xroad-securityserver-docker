# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/focal64"
  config.ssh.insert_key = false

  config.vm.provider :virtualbox do |v|
    v.memory = 1024
  end

  config.vm.define "node" do |node|
    node.vm.hostname = "node.local"

    # Ansible provisioning.
    node.vm.provision "ansible" do |ansible|
      ansible.limit = "all"
      ansible.playbook = "site_local.yml"
      ansible.become = true
      #ansible.galaxy_role_file = "requirements.yml"
      ansible.groups = {
        "all:vars"     => { "ansible_python_interpreter" => "/usr/bin/python3" },
      }
      # Enable ansible verbosity
      #ansible.verbose  = "vvvv"
      # Limit with tags
      #ansible.tags = "px-ss-configure"
    end

    # Delete deployments, services etc from k8
    node.trigger.after :destroy, :halt do |trigger|
      trigger.info = "Deleting services, deployments, postgresql helm and pvc from k8"
      trigger.run = {path: "delete_from_k8"}
    end
  end
end
