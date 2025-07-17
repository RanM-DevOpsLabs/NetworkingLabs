FROM linuxserver/openssh-server:amd64-version-10.0_p1-r7

# Configure SSH security settings during build
RUN echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
RUN echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
RUN echo "AuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config

# RUN mkdir /var/run/sshd
EXPOSE 22

CMD ["service", "ssh", "start"]
CMD ["/usr/sbin/sshd", "-D"]