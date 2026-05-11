package circus.robocalc.robosim.generator.cssp;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.xtext.diagnostics.Severity;
import org.eclipse.xtext.generator.GeneratorContext;
import org.eclipse.xtext.generator.JavaIoFileSystemAccess;
import org.eclipse.xtext.resource.XtextResourceSet;
import org.eclipse.xtext.util.CancelIndicator;
import org.eclipse.xtext.validation.CheckMode;
import org.eclipse.xtext.validation.IResourceValidator;
import org.eclipse.xtext.validation.Issue;

import com.google.inject.Injector;

import circus.robocalc.robosim.generator.cssp.sim.SimGenerator;
import circus.robocalc.robosim.textual.RoboSimStandaloneSetup;

public class TraductorService {
	private static final String[] ROBOCHART_LIBS = {
	        "lib/robochart/core.rct",
	        "lib/robochart/set_toolkit.rct",
	        "lib/robochart/sequence_toolkit.rct",
	        "lib/robochart/function_toolkit.rct",
	        "lib/robochart/relation_toolkit.rct"
	    };

	    private static final String[] ROBOSIM_LIBS = {
	        "lib/robosim/score.rst"
	    };

	    public static class Resultado {
	        public final boolean sucesso;
	        public final List<String> mensagens;
	        public final File pastaSaida;

	        public Resultado(boolean sucesso, List<String> mensagens, File pastaSaida) {
	            this.sucesso = sucesso;
	            this.mensagens = mensagens;
	            this.pastaSaida = pastaSaida;
	        }
	    }

	    /**
	     * Traduz um arquivo .rst para CSSP.
	     * @param inputFile arquivo .rst de entrada
	     * @param outputDir pasta de saída
	     * @param log callback para mensagens de progresso (pode ser null)
	     * @return resultado da tradução
	     */
	    public Resultado traduzir(File inputFile, File outputDir, Consumer<String> log) {
	        List<String> mensagens = new ArrayList<>();
	        Consumer<String> registrar = msg -> {
	            mensagens.add(msg);
	            if (log != null) log.accept(msg);
	        };

	        try {
	            registrar.accept("→ Inicializando Xtext standalone...");
	            Injector injector = new RoboSimStandaloneSetup()
	                    .createInjectorAndDoEMFRegistration();
	            XtextResourceSet rs = injector.getInstance(XtextResourceSet.class);

	            registrar.accept("→ Extraindo bibliotecas padrão...");
	            Path tempLibDir = Files.createTempDirectory("robosim-libs-");
	            tempLibDir.toFile().deleteOnExit();

	            for (String lib : ROBOCHART_LIBS) {
	                Path extracted = extractResource(lib, tempLibDir);
	                rs.getResource(URI.createFileURI(extracted.toString()), true);
	            }
	            for (String lib : ROBOSIM_LIBS) {
	                Path extracted = extractResource(lib, tempLibDir);
	                rs.getResource(URI.createFileURI(extracted.toString()), true);
	            }

	            registrar.accept("→ Carregando arquivos do projeto...");
	            File parentDir = inputFile.getAbsoluteFile().getParentFile();
	            if (parentDir != null && parentDir.isDirectory()) {
	                File[] siblings = parentDir.listFiles(f ->
	                    f.getName().endsWith(".rct") || f.getName().endsWith(".rst"));
	                if (siblings != null) {
	                    for (File sib : siblings) {
	                        if (!sib.equals(inputFile)) {
	                            rs.getResource(URI.createFileURI(sib.getAbsolutePath()), true);
	                            registrar.accept("   • " + sib.getName());
	                        }
	                    }
	                }
	            }

	            registrar.accept("→ Carregando " + inputFile.getName() + "...");
	            URI uri = URI.createFileURI(inputFile.getAbsolutePath());
	            Resource resource = rs.getResource(uri, true);
	            EcoreUtil.resolveAll(rs);

	            registrar.accept("→ Validando modelo...");
	            IResourceValidator validator = injector.getInstance(IResourceValidator.class);
	            List<Issue> issues = validator.validate(
	                    resource, CheckMode.ALL, CancelIndicator.NullImpl);

	            boolean hasErrors = false;
	            for (Issue issue : issues) {
	                String linha = "   [" + issue.getSeverity() + "] linha "
	                        + issue.getLineNumber() + ": " + issue.getMessage();
	                registrar.accept(linha);
	                if (issue.getSeverity() == Severity.ERROR) hasErrors = true;
	            }
	            if (issues.isEmpty()) {
	                registrar.accept("   (sem problemas)");
	            }
	            if (hasErrors) {
	                registrar.accept("\n❌ Modelo contém erros de validação. Geração cancelada.");
	                return new Resultado(false, mensagens, null);
	            }

	            registrar.accept("→ Gerando saída em " + outputDir.getAbsolutePath() + "...");
	            outputDir.mkdirs();
	            JavaIoFileSystemAccess fsa = injector.getInstance(JavaIoFileSystemAccess.class);
	            fsa.setOutputPath(outputDir.getAbsolutePath());

	            SimGenerator generator = injector.getInstance(SimGenerator.class);
	            generator.doGenerate(resource, fsa, new GeneratorContext());

	            registrar.accept("\n✅ Tradução concluída!");
	            return new Resultado(true, mensagens, outputDir);

	        } catch (Exception e) {
	            registrar.accept("\n❌ Erro: " + e.getMessage());
	            StringBuilder sb = new StringBuilder();
	            for (StackTraceElement st : e.getStackTrace()) {
	                sb.append("   at ").append(st).append("\n");
	            }
	            registrar.accept(sb.toString());
	            return new Resultado(false, mensagens, null);
	        }
	    }

	    private static Path extractResource(String resourcePath, Path destDir) throws IOException {
	        try (InputStream in = TraductorService.class.getClassLoader()
	                .getResourceAsStream(resourcePath)) {
	            if (in == null) {
	                throw new IOException("Recurso não encontrado: " + resourcePath);
	            }
	            Path target = destDir.resolve(resourcePath);
	            Files.createDirectories(target.getParent());
	            try (OutputStream out = Files.newOutputStream(target)) {
	                in.transferTo(out);
	            }
	            return target;
	        }
	    }
}
