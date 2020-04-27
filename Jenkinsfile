pipeline {
    agent any
    stages {
        stage('Stage 1') {
            steps {
                echo 'Hello world!' 
                sh 'ls -a roma'
                sh 'cat  bobo/ari.txt'
                sh 'ls -a bobo'
                stage('build') {
                   input{
		message "Press Ok to continue"
		submitter "user1,user2"
		parameters {
			string(name:'username', defaultValue: 'user', description: 'Username of the user pressing Ok')
		}
	}
	steps { 
		echo "User: ${username} said Ok."
	}
		}
	}
            }
        }
    }
}
