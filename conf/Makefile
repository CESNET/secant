all: ctx.add_user_secant

ctx.add_user_secant: user_data.yaml ctx.add_user_secant.template
	perl -pe 'BEGIN {$$SUB=`base64 -w 0 user_data.yaml`} s/\$$SECANT_USER_DATA/$$SUB/ge' < ctx.add_user_secant.template > $@

clean:
	$(RM) ctx.add_user_secant
